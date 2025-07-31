## Abstraction of the mech at the strategic level
class_name Mech
extends Node

@onready var regions: Array[MechRegion] = get_mech_region_children()


## Gets an array of all MechRegion children recursively and connects
## relevant signals.
func get_mech_region_children() -> Array[MechRegion]:
	# This actually aslo gets every node inheriting Node class soo... everything
	# Kinda bad but eh, convenience
	var children: Array[Node] = find_children("*", "Node")
	var result: Array[MechRegion]
	for child in children:
		if child is MechRegion:
			result.append(child)
	return result
