class_name AbilityListPanel
extends Control

signal request_ability_config_window(ability: CharacterAction)

@export var ability_list_item: Button

## TODO Take this to ability config
#@export var input_listener_scene: PackedScene

var ability_list_items: Array[Control]

var player: Player


func _ready() -> void:
	$ScrollContainer/KeybindButtonList/AbilityConfigButton.hide()


func add_ability_list_item(ability: CharacterAction) -> void:
	ability_list_item.icon = ability.icon
	ability_list_item.text = ability.ability_name.capitalize()

	## TODO Take this and put in the ability config 
	## God's most powerful assert
	#assert(InputMap.action_get_events(ability.ability_name).size() == 1 or \
	#InputMap.action_get_events(ability.ability_name).size() == 0,
	#ability.ability_name + \
	#" action has an invalid number of assigned input events of " + \
	#str(InputMap.action_get_events(ability.ability_name).size()))
	#
	#if InputMap.action_get_events(ability.ability_name).size() == 1:
		#list_item_button.text = \
		#InputMap.action_get_events(ability.ability_name)[0].as_text()
	#else:
		#list_item_button.text = "NONE"
	#list_item_button.pressed.connect(open_input_listener_popup.bind(ability))

	var new_list_item: Button = ability_list_item.duplicate()
	## TODO Take this to ability config
	#new_list_item.pressed.connect(open_input_listener_popup.bind(ability))

	new_list_item.pressed.connect(request_ability_config_window.emit.bind(ability))
	ability_list_items.append(new_list_item)
	ability_list_item.get_parent().add_child(new_list_item)
	new_list_item.show()

	#list_item_button.pressed.disconnect(open_input_listener_popup)


## TODO Take this to ability config
#func open_input_listener_popup(ability: CharacterAction) -> void:
	#var new_popup: InputListenerPopup = input_listener_scene.instantiate()
	#new_popup.ability = ability
	#new_popup.keybind_changed.connect(refresh_list.unbind(2))
	#new_popup.keybind_changed.connect(save_keybind)
	#get_tree().get_root().add_child.call_deferred(new_popup)


## TODO take this to ability config
#func save_keybind(ability_name: String, key: InputEvent):
	#var config_path: String = player.ability_keybind_cfg_path
	#var config: ConfigFile = ConfigFile.new()
	#if FileAccess.file_exists(player.ability_keybind_cfg_path):
		#config.load(config_path)
	#config.set_value("AbilityKeybinds", ability_name, key)
	#config.save(config_path)


func populate_list_with_current_abilities() -> void:
	for ability in player.abilities:
		if not ability.show_in_menus:
			continue
		add_ability_list_item(ability)
	for ability in player.repair_mode_abilities:
		if not ability.show_in_menus:
			continue
		add_ability_list_item(ability)


func clear_list() -> void:
	for item in ability_list_items:
		item.queue_free()
	ability_list_items.clear()


func refresh_list() -> void:
	clear_list()
	populate_list_with_current_abilities()
