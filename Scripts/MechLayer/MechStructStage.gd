@tool
class_name MechStructStage
extends Node3D



## Standardized amount of work needed to repair a stage. A equals to 1 second
## of work with a standard tool.
@export_range(0, 5, 0.1, "or_greater") var repair_time: float = 1
## Nodes outside the stage node tree hiererchy that will be treated as if they were inside of it.
@export var external_children: Array[Node3D]


func set_state(active: bool):
	#set_process(active)
	#set_physics_process(active)
	var new_process_mode: ProcessMode
	if active:
		new_process_mode = Node.PROCESS_MODE_INHERIT
	else:
		new_process_mode = Node.PROCESS_MODE_DISABLED

	visible = active
	process_mode = new_process_mode

	for node in external_children:
		node.visible = active
		node.process_mode = new_process_mode



func _on_hide_all_stages() -> void:
	set_state(false)
