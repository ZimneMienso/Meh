extends Resource
class_name EqSlot

## For UI update
signal equipment_changed
## For UI update
signal stack_size_changed

enum TAGS {
	EXOSKELETON
}

@export var name: String
@export var tags: Array[TAGS]
@export var icon: Texture2D


var current_equipment: Equipment:
	set(new):
		if current_equipment != new:
			current_equipment = new
			equipment_changed.emit()


var current_stack_size: int:
	set(new):
		if current_stack_size != new:
			current_stack_size = new
			stack_size_changed.emit()


## Check if given equipment can be placed in the given slot at this precise moment
func can_equip(tested_equipment: Equipment) -> bool:
	## Check if the slot if already occupied by a different equipment
	if current_equipment and current_equipment != tested_equipment:
		return false

	## Check if the slot has any matching tags with the equipment
	## For each tag the slot has
	var tag_compatible: bool = false
	for tag in tags:
		## Check if the equipment also has it
		if tested_equipment.tags.has(tag):
			tag_compatible = true
			break
	if not tag_compatible:
		return false

	## Check if we can fit one more equipment of this type
	if current_stack_size >= tested_equipment.max_stack_size:
		return false

	## All fail cases are false
	return true
	
	
	
