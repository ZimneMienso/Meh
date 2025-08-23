class_name InputListenerPopup
extends Control

# TODO make the input handling clean and predictable

## Notifies the keybinds panel to refresh
signal keybind_changed(new_input_event: InputEvent)

@export var instruction_label: Label
@export var status_label: Label
@export var confirm_button: Button
@export var cancel_button: Button
@export var close_button: Button

const catch_message: String = \
"Confirm to apply the keybind
Cancel to reset"

var setting: AbilitySettingKeybind

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
func catch(event: InputEvent = null) -> void:
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
func apply() -> void:
	var action_name: String = setting.action_name
	assert(InputMap.has_action(
		action_name), "Missing action for " + action_name)

	## Reset action if it has events assigned.
	if InputMap.action_get_events(action_name).size() > 0:
			InputMap.erase_action(action_name)
			InputMap.add_action(action_name)

	## If the player cleared the input, stop here.
	if not keybind_candidate:
		keybind_changed.emit(keybind_candidate)
		queue_free()
		return

	## Assign the new keybind
	InputMap.action_add_event(action_name, keybind_candidate)
	keybind_changed.emit(keybind_candidate)
	
	
	### If no event is bound to the given action, add the candidate event
	#if InputMap.action_get_events(action_name).size() == 0:
		#InputMap.action_add_event(action_name, keybind_candidate)
		#keybind_changed.emit(keybind_candidate)
		#
	### If the current event is not the candidate, change it
	#elif InputMap.action_get_events(action_name)[0] != keybind_candidate:
		#InputMap.action_erase_events(action_name)
		#InputMap.action_add_event(action_name, keybind_candidate)
		#keybind_changed.emit(keybind_candidate)
	### Last case being: there is more than zero events and 
	### the first one is equal to the current candidate
	queue_free()
