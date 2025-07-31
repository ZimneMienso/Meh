## Abstraction of a part of a mech that can be targeted independently.
class_name MechRegion
extends Node

## Can the region be acquired as a target
@export var targetable: bool = true
## Can the region have holes (for the player to repair)
@export var perforable: bool = false
## Damage taken will be redirected randomly to these systems if they have any
## durability left
@export var protected_by: Array[MechRegion]
## When at 0 durability, damage taken will be redirected to these regions
## randomly.
@export var overflow_damage_to: Array[MechRegion]
## Max "HP" of the particular region.
@export_range(0, 100, 1, "or_greater") var max_durability: float

## Objects that represent the repairable damage in the 3D space assigned to this
## mech region.
@onready var destructibles: Array[MechStruct] = get_mech_struct_children()
## "HP" of the particular region.
@onready var durability: float = max_durability
@onready var chip_damage_treshold: float = get_chip_damage_treshold()

## Any damage left after a hit that was insufficient to cause structure damage.
var chip_damage: float = 0


func _ready() -> void:
	pass


## Take a hit. If the region is perforable, accumulate the damage and affect
## durability only when there's enough accumulated damage to make a hole.
## Else just decrease durability.
## Returns true if durability was decreased.
func receive_damage(value: float) -> bool:
	var durability_hit: bool = false
	if perforable:
		chip_damage += value
		while chip_damage >= chip_damage_treshold:
			if perforable:
				perforate()
			chip_damage -= chip_damage_treshold
			durability -= chip_damage_treshold
			durability_hit = true
	else:
		durability -= value
		durability_hit = true
	return durability_hit


## When a damaged struct in the region is repaired, regain durability
func on_struct_repaired():
	durability += chip_damage_treshold


## Damage a random surviving struct assigned to the region
func perforate():
	var surviving_structs: Array[MechStruct] = \
	destructibles.filter(MechStruct.can_be_damaged)
	var hole_to_be: MechStruct = surviving_structs.pick_random() as MechStruct
	hole_to_be.increase_stage()


## Gets an array of all MechStruct children and connects relevant signals.
func get_mech_struct_children() -> Array[MechStruct]:
	var children: Array[Node] = get_children()
	var result: Array[MechStruct]
	for child in children:
		if child is MechStruct:
			result.append(child)
			child.struct_repaired.connect(on_struct_repaired)
	return result


## If perforable, returns the amount of damage the region needs to receive
## before sustaining structural damage
## Else, 0
func get_chip_damage_treshold() -> float:
	if not perforable:
		return 0
	var stage_count: int = 0
	for struct in destructibles:
		stage_count += struct.max_stage
	return max_durability / stage_count
