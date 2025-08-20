@tool
class_name AttributeModifier
extends Resource

enum TYPE {
 ADD,
 MULTIPLIER
}

@export var attribute_type: Attribute.TYPE = Attribute.TYPE.NULL:
	set(value):
		attribute_type = value
		resource_name = Attribute.TYPE.find_key(value).capitalize()
@export var bonus_type: TYPE
@export var value: float = 0
