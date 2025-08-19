## Abstraction of a part of a mech that can be targeted independently.
class_name MechRegion
extends Node


## Max "HP" of the particular region.
@export_range(0, 100, 1, "or_greater") var max_durability: float
## Can the region be acquired as a target
@export var targetable: bool = true
## Can the region have holes (for the player to repair)
@export var perforable: bool = false
## Damage event will be redirected randomly to one of those regions. If the
## region the damage has been redirected to cannot be damaged (because, for example,
## it is destroyed), the damage will be dealt normally.
@export var protected_by: Array[MechRegion]
## When at 0 durability, damage taken will be redirected to these regions
## randomly.
@export var overflow_damage_to: Array[MechRegion]

## Objects that represent the repairable damage in the 3D space assigned to this
## mech region.
@onready var destructibles: Array[MechStruct] = get_mech_struct_children()
## "HP" of the particular region.
@onready var durability: float = max_durability
@onready var chip_damage_treshold: float = get_chip_damage_treshold()

## Any damage left after a hit that was insufficient to cause structure damage.
var chip_damage: float = 0

@onready var mech_parent: Mech = find_mech_parent()


static func can_be_damaged(region: MechRegion) -> bool:
	if region.durability <= 0:
		return false
	return true


func _ready() -> void:
	## Append yourself to the region list of the parent mech.
	mech_parent.regions.append(self)


## Take a hit. If the region is perforable, accumulate the damage and affect
## durability only when there's enough accumulated damage to make a hole.
## Else just decrease durability.
## Returns true if durability was decreased.
func receive_damage(value: float) -> void:
	if protected_by:
		var redirect_to: MechRegion = protected_by.pick_random() as MechRegion
		if MechRegion.can_be_damaged(redirect_to):
			redirect_to.receive_damage(value)
			return
	if perforable:
		chip_damage += value
		while chip_damage >= chip_damage_treshold:
			perforate()
			chip_damage -= chip_damage_treshold
			durability -= chip_damage_treshold
	else:
		durability -= value
	## Evaluate overflow
	if durability < 0:
		if overflow_damage_to:
			var overflow_target: MechRegion = overflow_damage_to.pick_random() as MechRegion
			overflow_target.receive_damage(abs(durability))
		durability = 0



## When a damaged struct in the region is repaired, regain durability
func on_struct_repaired():
	## If that was the last damaged structure, max out the durability
	## and reset chip damage
	if destructibles.size() == \
	destructibles.filter(MechStruct.can_be_damaged).size():
		durability = max_durability
		chip_damage = 0
	## Otherwise, just repair
	else:
		durability += chip_damage_treshold


## Damage a random surviving struct assigned to the region
func perforate():
	var surviving_structs: Array[MechStruct] = \
	destructibles.filter(MechStruct.can_be_damaged)
	assert(destructibles, "Attempted to perforate a system with no damageable structures.")
	if not surviving_structs:
		return
	var hole_to_be: MechStruct = surviving_structs.pick_random() as MechStruct
	hole_to_be.damage()


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


func find_mech_parent() -> Mech:
	var mech: Mech = null
	var parent: Node = self
	while mech == null:
		parent = parent.get_parent()
		assert(parent, "Parent (or ancestor) Mech couldn't be found.")
		if parent is Mech:
			mech = parent
	return mech
