extends AttributeOld
class_name AttributeI

enum TYPE {
	ABILITY
}

@export var type: TYPE
@export var value: int = 1

func get_value() -> int:
	return value
