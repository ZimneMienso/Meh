extends Node3D

@onready var interacting_player_position_reference: Marker3D = $InteractingPlayerPositionReference
@onready var interactable: Area3D = $Interactable


var player_position_before_interaction: Vector3
var player: Player


func _on_interaction() -> void:
	## Get interacting player
	var overlaping_bodies: Array[Node3D] = interactable.get_overlapping_bodies()
	if overlaping_bodies[0] is Player:
		player = overlaping_bodies[0]
	else:
		printerr("Non-player detected by interactable ", interactable)
		return
	player_position_before_interaction = player.global_position
	
	## Set the camera to loadout mode
	CAMERAMAN.loadout_mode()
	player.global_position = interacting_player_position_reference.global_position
	player.set_physics_process(false)
	interactable.monitoring = false
	
	## Open loadout UI and connect to exit from loadout
	show_loadout_menu()


## When connecting a signal to this, also pass that signal as an argument
## so it can be disconnected
func _on_exit_from_loadout_screen(close_menu_signal: Signal) -> void:
	CAMERAMAN.default_mode()
	player.global_position = player_position_before_interaction
	player.set_physics_process(true)
	close_menu_signal.disconnect(_on_exit_from_loadout_screen)
	interactable.monitoring = true


## The object only opens the menu, the menu handles closing itself
## and sends a signal when it does so player can be returned to normal state
func show_loadout_menu():
	## Get the node
	var inventory_menu: LoadoutScreen = %LoadoutScreen
	
	## Open the menu
	inventory_menu.open(player)
	
	## Connect a signal that will reset the camera, position, etc on closing
	var close_menu_signal: Signal = inventory_menu.loadout_menu_closed
	close_menu_signal.connect(
		_on_exit_from_loadout_screen.bind(close_menu_signal)
		)
