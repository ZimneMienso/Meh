extends Resource
class_name AttributeModifier

enum TYPE {
 ADD,
 MULTIPLIER
}

@export var attribute_type: Attribute.TYPE
@export var bonus_type: TYPE
@export var value: float = 0
