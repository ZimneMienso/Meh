class_name AttributeModifier
extends Resource

enum TYPE {
 ADD,
 MULTIPLIER
}

@export var attribute_type: Attribute.TYPE = Attribute.TYPE.NULL
@export var bonus_type: TYPE
@export var value: float = 0
