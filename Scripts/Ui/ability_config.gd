class_name AbilityConfigScreen
extends Control

signal ability_config_closed

@export var input_listener_scene: PackedScene

var displayed_settings: Array[Control]


func _ready() -> void:
	%SliderSetting.hide()
	%CheckBoxSetting.hide()
	%KeybindSetting.hide()


func display_ability(ability: CharacterAction) -> void:
	## Header.
	%AbilityIcon.texture = ability.icon
	%AbilityNameLabel.text = ability.ability_name

	## Settings.
	## Clear any previous.
	for setting in displayed_settings:
		setting.queue_free()
	displayed_settings.clear()
	## Extract the possible settings from the ability.
	## Create control nodes to display them.
	for setting in ability.player_settings:
		create_setting_ui(setting)
	
	## Show 'em
	show()


static func update_slider_value_label(value: float, label: Label, suffix: String) -> void:
	label.text = str(value) + " " + suffix


static func update_keybind_button(key: InputEvent, button: Button):
	if key:
		button.text = key.as_text()
	else:
		button.text = "UNASSIGNED"


func create_setting_ui(setting: AbilitySetting) -> void:
	var new_setting: Control
	if setting is AbilitySettingBool:
		## Setup the template.
		%CheckboxLabel.text = setting.setting_text
		%CheckBox.button_pressed = setting.get_value()

		## Create an instance.
		new_setting = %CheckBoxSetting.duplicate()
		%CheckBoxSetting.get_parent().add_child(new_setting)

		## Connect the toggle to the value
		var box: CheckBox = new_setting.find_child(%CheckBox.name, true, false)
		box.toggled.connect(setting.set_value)

	if setting is AbilitySettingInt:
		## Setup the template.
		%SliderLabel.text = setting.setting_text
		%Slider.min_value = setting.min_value
		%Slider.max_value = setting.max_value
		%Slider.step = 1
		%Slider.value = setting.get_value()
		update_slider_value_label(setting.value, %SliderValueLabel, setting.suffix)

		## Create an instance.
		new_setting = %SliderSetting.duplicate()
		%SliderSetting.get_parent().add_child(new_setting)

		## Connect the slider to the value and value display.
		var slider: HSlider = new_setting.find_child(%Slider.name, true, false)
		var value_label: Label = new_setting.find_child(%SliderValueLabel.name, true, false)
		slider.value_changed.connect(update_slider_value_label.bind(value_label, setting.suffix))
		slider.value_changed.connect(setting.set_value)

	if setting is AbilitySettingFloat:
		## Setup the template.
		%SliderLabel.text = setting.setting_text
		%Slider.min_value = setting.min_value
		%Slider.max_value = setting.max_value
		%Slider.step = setting.step
		%Slider.value = setting.get_value()
		update_slider_value_label(setting.value, %SliderValueLabel, setting.suffix)

		## Create an instance.
		new_setting = %SliderSetting.duplicate()
		%SliderSetting.get_parent().add_child(new_setting)

		## Connect the slider to the value and value display.
		var slider: HSlider = new_setting.find_child(%Slider.name, true, false)
		var value_label: Label = new_setting.find_child(%SliderValueLabel.name, true, false)
		slider.value_changed.connect(update_slider_value_label.bind(value_label, setting.suffix))
		slider.value_changed.connect(setting.set_value)

	if setting is AbilitySettingKeybind:
		## Setup the template.
		%KeybindLabel.text = setting.setting_text.capitalize()
		if InputMap.action_get_events(setting.action_name).size() == 1:
			%KeybindButton.text = \
			InputMap.action_get_events(setting.action_name)[0].as_text()
		else:
			%KeybindButton.text = "UNASSIGNED"
		## Create an instance.
		new_setting = %KeybindSetting.duplicate()
		%KeybindSetting.get_parent().add_child(new_setting)
		## Connect the button to the input config popup.
		var button: Button = new_setting.find_child(%KeybindButton.name, true, false)
		button.pressed.connect(open_input_listener_popup.bind(setting, button))

	## Register and show the setting.
	displayed_settings.append(new_setting)
	new_setting.show()


func close() -> void:
	ability_config_closed.emit()
	hide()


func save_keybind(key: InputEvent, action_name: String):
	var config_path: String = Player.ability_keybind_cfg_path
	var config: ConfigFile = ConfigFile.new()
	if FileAccess.file_exists(Player.ability_keybind_cfg_path):
		config.load(config_path)
	config.set_value("AbilityKeybinds", action_name, key)
	config.save(config_path)


func open_input_listener_popup(
	setting: AbilitySettingKeybind, button_to_update: Button) -> void:

	var new_popup: InputListenerPopup = input_listener_scene.instantiate()
	new_popup.setting = setting
	new_popup.keybind_changed.connect(
		save_keybind.bind(setting.action_name))
	new_popup.keybind_changed.connect(
		update_keybind_button.bind(button_to_update))
	get_tree().get_root().add_child.call_deferred(new_popup)
	
