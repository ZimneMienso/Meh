class_name AbilityConfigScreen
extends Control

signal ability_config_closed

var displayed_settings: Array[Control]


func _ready() -> void:
	%SliderSetting.hide()
	%CheckBoxSetting.hide()


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

	## Register and show the setting.
	displayed_settings.append(new_setting)
	new_setting.show()


func close() -> void:
	ability_config_closed.emit()
	hide()
