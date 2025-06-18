extends Node

var equipment_in_inventory: Dictionary[Equipment, int]


func add_equipment(equipment: Equipment, amount: int = 1) -> void:
	if not equipment_in_inventory.has(equipment):
		equipment_in_inventory.set(equipment, amount)
	else:
		equipment_in_inventory[equipment] += amount


func subtract_equipment(equipment: Equipment, amount: int = 1) -> void:
	if \
	not equipment_in_inventory.has(equipment) \
	or equipment_in_inventory[equipment] < amount:
		printerr("Attempted to remove equipment that is not in inventory")
		return
	equipment_in_inventory[equipment] -= amount


func transfer_equipment_to_slot(equipment: Equipment, slot: EqSlot):
	if slot.current_equipment == equipment:
		slot.current_stack_size += 1
	else:
		slot.current_equipment = equipment
	subtract_equipment(equipment)


func transfer_equipment_to_inventory(slot: EqSlot):
	add_equipment(slot.current_equipment)
	slot.current_stack_size -= 1
	if slot.current_stack_size <= 0:
		slot.current_equipment = null
