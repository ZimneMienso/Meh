extends Resource
class_name Equipment

@export var name: String
@export var icon: Texture2D
@export var attribute_modifiers: Array[AttributeModifier]
@export var abilities: Array[CharacterAction]
@export var tags: Array[EqSlot.TAGS]
## This is for equipment addons
@export var eqslots: Array[EqSlot] = []
## The maximum number of copies of that equipment you can have in a single slot
@export var max_stack_size: int = 1
## Dictionary of scenes that will be instantiated and attached to the
## bones identified by the string value in the player armature.
@export var equipment_nodes: Dictionary[PackedScene, String]
