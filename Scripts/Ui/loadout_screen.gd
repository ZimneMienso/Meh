extends Control
class_name LoadoutScreen

signal loadout_menu_closed

@export var inventory_item_button_pattern: Button
@export var inventory_buttons_container: Container

@export var loadout_slot_button_pattern: Button
@export var loadout_buttons_container: Container

@export var ability_keybind_panel: AbilityKeybindsPanel

var inventory_item_buttons: Array[Button]
var loadout_slot_buttons: Array[Button]



var player: Player


func open(opening_player: Player) -> void:
	player = opening_player
	ability_keybind_panel.player = player
	create_buttons_from_inventory_data()
	create_buttons_from_loadout_data()
	show()

	ability_keybind_panel.populate_list_with_current_abilities()


func close() -> void:
	hide()
	loadout_menu_closed.emit()
	ability_keybind_panel.clear_list()


## This removes all buttons in the loadout window and creates new ones based on
## the the data held in INV singleton, which is to say, the players "storage".
## When clicked, they find a matching slot in the players EqSlots and check if
## equpping is possible, and if true, they equip the item and free themselves.
func create_buttons_from_inventory_data() -> void:
	clear_inventory_buttons()
	for equipment in INV.equipment_in_inventory:
		if INV.equipment_in_inventory[equipment] > 0:
			var new_button: Button = inventory_item_button_pattern.duplicate()
			inventory_item_buttons.append(new_button)
			new_button.show()
			new_button.text = equipment.name
			new_button.icon = equipment.icon
			new_button.pressed.connect(
				on_inventory_item_clicked.bind(equipment, new_button))
			inventory_buttons_container.add_child(new_button)


## This removes all buttons in the loadout window and creates new ones based on
## the EqSlots of the player. If clicked, depending if they are occupied by
## equipment, either requests unequiping the item, or TODO apply a filter to the
## inventory window that shows only equipment with matching tags.
func create_buttons_from_loadout_data() -> void:
	clear_loadout_slot_buttons()
	var loadout_slots: Array[EqSlot] = player.get_loadout_slots()
	for slot in loadout_slots:
		var new_button: Button = loadout_slot_button_pattern.duplicate()
		loadout_slot_buttons.append(new_button)
		new_button.show()
		update_loadout_button(new_button, slot)

		# Workaround for the fact that a direct connection to the
		# update_button function would necessitate a way of tracking and
		# disconnecting individual connections when freeing the buttons.
		## Define a new user signal and add it to the button
		const button_update_signal_name: StringName = "request_button_update"
		new_button.add_user_signal(button_update_signal_name)
		## Connect the origin of the signal chain to the middle-man (button)
		slot.equipment_changed.connect(
			new_button.emit_signal.bind(button_update_signal_name))
		## Connect the middle-man (button) to the button update
		## This way when the button is freed,
		## the signals disconnect automatically
		new_button.connect(
			button_update_signal_name,
			update_loadout_button.bind(new_button, slot)
		)


		new_button.pressed.connect(on_loadout_slot_button_clicked.bind(slot))

		loadout_buttons_container.add_child(new_button)


func clear_inventory_buttons() -> void:
	for button in inventory_item_buttons:
		button.queue_free()
	inventory_item_buttons.clear()


func clear_loadout_slot_buttons() -> void:
	for button in loadout_slot_buttons:
		button.queue_free()
	loadout_slot_buttons.clear()


func on_inventory_item_clicked(button_equipment_data: Equipment, button: Button) -> void:
	var viable_slots: Array[EqSlot] = \
		player.get_loadout_slots_matching_equipment(button_equipment_data)
	for slot in viable_slots:
		if slot.can_equip(button_equipment_data):
			INV.transfer_equipment_to_slot(button_equipment_data, slot)
			# TODO maybe don't nuke everything every time the player clicks something
			player.initialize_equipment()
			button.queue_free()
			inventory_item_buttons.erase(button)
			break


func on_loadout_slot_button_clicked(slot: EqSlot) -> void:
	if slot.current_equipment:
		INV.transfer_equipment_to_inventory(slot)
		# TODO maybe don't nuke everything every time the player clicks something
		player.initialize_equipment()
		create_buttons_from_inventory_data()


func update_loadout_button(button: Button, slot: EqSlot):
	if slot.current_equipment:
		button.icon = slot.current_equipment.icon
		button.text = slot.current_equipment.name
	else:
		button.icon = slot.icon
		button.text = slot.name
