@tool
class_name MechStructStage
extends Node3D



## Standardized amount of work needed to repair a stage. A equals to 1 second
## of work with a standard tool.
@export_range(0, 5, 0.1, "or_greater") var repair_time: float = 1


func set_state(active: bool):
	#set_process(active)
	#set_physics_process(active)
	visible = active
	if active:
		process_mode = Node.PROCESS_MODE_INHERIT
	else:
		process_mode = Node.PROCESS_MODE_DISABLED


func _on_hide_all_stages() -> void:
	set_state(false)
