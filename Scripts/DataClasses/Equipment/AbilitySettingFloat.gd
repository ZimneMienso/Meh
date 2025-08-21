class_name AbilitySettingFloat
extends AbilitySetting

@export var default_value: float
@export var max_value: float
@export var min_value: float
@export var step: float
@export var suffix: String
var value: float


func _init() -> void:
	value_type = VALUE_TYPES.FLOAT


func get_value() -> float:
	return value


func set_value(new_value) -> void:
	assert(new_value is float)
	value = new_value
