## A variable exposed to the player in the ability settings.
class_name AbilitySetting
extends Resource

enum VALUE_TYPES {
	BOOL,
	INT,
	FLOAT
}

var value_type: VALUE_TYPES

@export var setting_text: String
