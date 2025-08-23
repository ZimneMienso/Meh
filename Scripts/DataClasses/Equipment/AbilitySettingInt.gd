class_name AbilitySettingInt
extends AbilitySetting

@export var default_value: int
@export var max_value: int
@export var min_value: int
@export var suffix: String
var value: int


func _init() -> void:
	value_type = VALUE_TYPES.INT


func get_value() -> int:
	return value


func set_value(new_value: int) -> void:
	value = new_value
