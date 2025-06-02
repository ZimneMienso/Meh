extends Resource
class_name Equipment

@export var icon: Texture2D
@export var attribute_modifiers: Array[AttributeModifier]
@export var ability_component: Array
@export var tags: Array[EqSlot.TAGS]
## This is for equipment addons
@export var eqslots: Array[EqSlot] = []
## The maximum number of copies of that equipment you can have in a single slot
@export var max_stack_size: int = 1
