class_name AbilityKeybindsPanel
extends Control

@export var keybind_list_item: Container
@export var list_item_icon: TextureRect
@export var list_item_label: Label
@export var list_item_button: Button

@export var input_listener_scene: PackedScene

var keybind_list_items: Array[Control]

var player: Player


func add_keybind_list_item(ability: CharacterAction) -> void:
	list_item_icon.texture = ability.icon
	list_item_label.text = ability.ability_name.capitalize()

	# God's most powerful assert
	assert(InputMap.action_get_events(ability.ability_name).size() == 1 or \
	InputMap.action_get_events(ability.ability_name).size() == 0,
	ability.ability_name + \
	" action has an invalid number of assigned input events of " + \
	str(InputMap.action_get_events(ability.ability_name).size()))

	if InputMap.action_get_events(ability.ability_name).size() == 1:
		list_item_button.text = \
		InputMap.action_get_events(ability.ability_name)[0].as_text()
	else:
		list_item_button.text = "NONE"
	#list_item_button.pressed.connect(open_input_listener_popup.bind(ability))

	var new_list_item: Control = keybind_list_item.duplicate()
	# TODO Figure out why duplicate doesn't do that properly, see how it has
	# been done in loadout slot button
	var new_list_item_button: Button = new_list_item.get_child(2)
	new_list_item_button.pressed.connect(open_input_listener_popup.bind(ability))

	keybind_list_items.append(new_list_item)
	keybind_list_item.get_parent().add_child(new_list_item)
	new_list_item.show()

	#list_item_button.pressed.disconnect(open_input_listener_popup)


func open_input_listener_popup(ability: CharacterAction) -> void:
	var new_popup: InputListenerPopup = input_listener_scene.instantiate()
	new_popup.ability = ability
	new_popup.keybind_changed.connect(refresh_list.unbind(2))
	new_popup.keybind_changed.connect(save_keybind)
	get_tree().get_root().add_child.call_deferred(new_popup)


func save_keybind(ability_name: String, key: InputEvent):
	var config_path: String = player.ability_keybind_cfg_path
	var config: ConfigFile = ConfigFile.new()
	if FileAccess.file_exists(player.ability_keybind_cfg_path):
		config.load(config_path)
	config.set_value("AbilityKeybinds", ability_name, key)
	config.save(config_path)


func populate_list_with_current_abilities() -> void:
	for ability in player.abilities:
		if not ability.create_input_action:
			continue
		add_keybind_list_item(ability)


func clear_list() -> void:
	for item in keybind_list_items:
		item.queue_free()
	keybind_list_items.clear()


func refresh_list() -> void:
	clear_list()
	populate_list_with_current_abilities()
