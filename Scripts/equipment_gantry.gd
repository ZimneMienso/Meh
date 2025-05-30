extends Node3D

@onready var interacting_player_position_reference: Marker3D = $InteractingPlayerPositionReference

var player_position_before_interaction: Vector3
var player: Player

func _on_interaction() -> void:
	
	print("Here be inventory")
	## Get interacting player
	var overlaping_bodies: Array[Node3D] = $Interactable.get_overlapping_bodies()
	if overlaping_bodies[0] is Player:
		player = overlaping_bodies[0]
	else:
		printerr("Non-player detected by interactable ", $Interactable)
		return
	player_position_before_interaction = player.global_position
	
	## Set the camera to loadout mode
	CAMERAMAN.loadout_mode()
	player.global_position = interacting_player_position_reference.global_position
	player.set_physics_process(false)
	
	## Open loadout UI and connect to exit from loadout
	show_inventory_menu()

## When connecting a signal to this, also pass that signal as an argument
## so it can be disconnected
func _on_exit_from_loadout_screen(close_menu_signal: Signal) -> void:
	CAMERAMAN.default_mode()
	player.global_position = player_position_before_interaction
	player.set_physics_process(true)
	close_menu_signal.disconnect(_on_exit_from_loadout_screen)
	


## The object only opens the menu, the menu handles closing itself
## and sends a signal when it does so player can be returned to normal state
func show_inventory_menu():
	## Get the node
	var inventory_menu: Control = $"../Control/InventoryMenu"
	
	## Set the visibility
	inventory_menu.show()
	
	## Connect a signal that will reset the camera, position, etc on closing
	# TODO visibility_changed can cause bugs because it is also emitted
	# when parent visibility is changed
	var close_menu_signal: Signal = inventory_menu.visibility_changed
	close_menu_signal.connect(
		_on_exit_from_loadout_screen.bind(close_menu_signal)
		)
