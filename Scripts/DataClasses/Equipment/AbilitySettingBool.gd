class_name AbilitySettingBool
extends AbilitySetting

@export var default_value: bool
var value: bool


func _init() -> void:
	value_type = VALUE_TYPES.BOOL


func get_value() -> bool:
	return value


func set_value(new_value: bool) -> void:
	value = new_value
