## Abstraction of the mech at the strategic level
class_name Mech
extends Node

signal died

@onready var regions: Array[MechRegion]# = get_mech_region_children()
@onready var targetable_regions: Array[MechRegion] = filter_targetable_regions(regions)


static func filter_targetable_regions(
	regions_to_filter: Array[MechRegion]) -> Array[MechRegion]:
	return regions_to_filter.filter(
		func(region: MechRegion) -> bool: 
			if region.targetable:
				return true
			return false
			)


func _ready() -> void:
	## If not overrided, assume it's an enemy mech
	assert(MECH_SPACE.enemy == null, "Attempted to instantiate an enemy while another was present.")
	MECH_SPACE.enemy = self
	died.connect(MECH_SPACE._on_enemy_death)


### Gets an array of all MechRegion children recursively and connects
### relevant signals.
#func get_mech_region_children() -> Array[MechRegion]:
	## This actually aslo gets every node inheriting Node class soo... everything
	## Kinda bad but eh, convenience
	#var children: Array[Node] = find_children("*", "Node")
	#var result: Array[MechRegion]
	#for child in children:
		#if child is MechRegion:
			#result.append(child)
	#return result


func die() -> void:
	died.emit()
