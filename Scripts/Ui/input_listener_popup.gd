class_name InputListenerPopup
extends Control

# TODO make the input handling clean and predictable

signal keybind_changed

@export var instruction_label: Label
@export var status_label: Label
@export var confirm_button: Button
@export var cancel_button: Button
@export var close_button: Button

const catch_message: String = \
"Confirm to apply the keybind
Cancel to reset"

var ability: CharacterAction

var listening: bool
var keybind_candidate: InputEvent


func _ready() -> void:
	confirm_button.pressed.connect(apply)
	cancel_button.pressed.connect(listen)
	cancel_button.pressed.connect(close_button.grab_focus.call_deferred)
	close_button.pressed.connect(queue_free)
	grab_focus.call_deferred()

	listen()


func _input(event: InputEvent) -> void:
	if not listening:
		return

	if event is InputEventKey:
		if event.keycode == KEY_ESCAPE:
			catch()
			return
		elif event == confirm_button.shortcut.events[0]:
			catch(event)
			return
		else:
			catch(event)
			return

	if event is InputEventMouseButton:
		catch(event)
		grab_focus()
		return


## Start listening to player input
func listen():

	listening = true
	status_label.text = "Listening..."
	instruction_label.text = \
	"Press key to assign
	Escape to clear"
	confirm_button.hide()
	cancel_button.hide()


## Present the event or NONE as the candidate for the hotkey
func catch(event: InputEvent = null):
	if event == null:
		status_label.text = "Keybind: NONE"
	else:
		status_label.text = "Keybind: " + event.as_text()
	instruction_label.text = catch_message
	confirm_button.show()
	cancel_button.show()
	keybind_candidate = event
	listening = false


## Assign the keybind to the action
func apply():
	assert(InputMap.has_action(
		ability.ability_name), "Missing action for " + ability.ability_name)
	if InputMap.action_get_events(ability.ability_name).size() == 0:
		InputMap.action_add_event(ability.ability_name, keybind_candidate)
		keybind_changed.emit()
		queue_free()
		return
	if InputMap.action_get_events(ability.ability_name)[0] != keybind_candidate:
		InputMap.action_erase_events(ability.ability_name)
		InputMap.action_add_event(ability.ability_name, keybind_candidate)
		keybind_changed.emit()
	## Last case being: there is more than zero events and 
	## the first one is equal to the current candidate
	queue_free()
