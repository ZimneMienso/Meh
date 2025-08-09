## Represents a node of repairable damage in the 3D space within a mech region.
class_name MechStruct
extends Area3D

signal struct_repaired

## The scenes that will be shown for each particular stage of damage.
## Stage 0 is intact, stages[max_stage] is completely destroyed.
@export var stages: Array[PackedScene]
## Standardized amount of work needed to repair a stage. A equals to 1 second
## of work with a standard tool.
@export_range(0, 5, 0.1, "or_greater") var repair_time: float = 1

@onready var max_stage: int = stages.size() - 1

var stage: int = 0
var stage_instance: Node
var repair_progress: float


static func can_be_damaged(struct: MechStruct) -> bool:
	if struct.stage < struct.max_stage:
		return true
	return false


func _ready() -> void:
	assert(stages.size() >= 2, "The struct has less than 2 stages, meaning it does nothing")


func receive_repair(value: float) -> void:
	repair_progress += value
	if repair_progress >= repair_time:
		decrese_stage()
		repair_progress = 0


## Reminder: higher stage -> more damaged
func increase_stage():
	assert(stage < max_stage, "Attempted to damage a MechStruct beyond it's max stage.")

	## Enable the struct when increasing from stage 0
	if stage == 0:
		monitorable = true
	stage += 1
	change_stage(stages[stage])


## Reminder: lower stage -> less damaged
func decrese_stage():
	assert(stage > 0, "Attempted to repair a pristine (stage == 0) MechStruct.")

	stage -= 1
	## Disable the struct when decreasing to stage 0
	if stage == 0:
		monitorable = false
	change_stage(stages[stage])
	struct_repaired.emit()


## Make the current stage visuals disappear and show the new stage visuals
func change_stage(new_stage: PackedScene) -> void:
	if stage_instance:
		stage_instance.queue_free()

	if new_stage:
		var new_stage_instance: Node = new_stage.instantiate()
		add_child(new_stage_instance)
		stage_instance = new_stage_instance
