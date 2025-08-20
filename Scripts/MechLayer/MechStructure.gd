@tool
## Represents a node of repairable damage in the 3D space within a mech region.
class_name MechStruct
extends StaticBody3D

signal struct_repaired
signal hide_all_stages

const struct_collision_layer: int = 4

@export_tool_button("Setup/Reset") var setup_callable := setup
@export_tool_button("Add Stage") var add_stage_callable := add_stage
@export_tool_button("Remove Stage") var remove_stage_callable := remove_stage


@export_storage var max_stage: int = 2:
	set(value):
		if value < 2:
			print("max_stage attempted set to lower than 2, meaning the struct looses it's functionality. Setting to 2.")
			value = 2
		max_stage = value
		if max_stage < active_stage:
			change_stage(max_stage)


@export_range(1, 5, 1, "or_greater") var active_stage: int = 1:
	set(value):
		if value > max_stage:
			print("Active stage set to higher than max_stage, setting to max_stage.")
			value = max_stage
		if value < 1:
			print("Active stage set below 1 (fully repaired), setting to 1.")
			value = 1
		if stages.size() < active_stage or not stages[active_stage - 1]:
			await self.ready
		change_stage(value)
		active_stage = value


@export var stages: Array[MechStructStage]
## Standardized amount of work needed to repair a stage. A equals to 1 second
## of work with a standard tool.
var repair_time: float

@export var default_audio: AudioStream

@export var stage_holder: Node3D
var repair_progress: float

var audio_player: AudioStreamPlayer3D


static func can_be_damaged(struct: MechStruct) -> bool:
	if struct.active_stage < struct.max_stage:
		return true
	return false


func _ready() -> void:
	if Engine.is_editor_hint():
		if not stage_holder:
			setup()
		return

	assert(stages.size() >= 2, "The struct has less than 2 stages, meaning it does nothing")

	audio_player = AudioStreamPlayer3D.new()
	audio_player.stream = default_audio
	add_child(audio_player)


func receive_repair(value: float) -> void:
	if active_stage == 1:
		return
	repair_progress += value
	if repair_progress >= repair_time:
		repair()
		repair_progress = 0


## Reminder: higher stage -> more damaged
func damage() -> void:
	active_stage += 1
	play_sound()


## Reminder: lower stage -> less damaged
func repair() -> void:
	active_stage -= 1
	struct_repaired.emit()


## Make the current stage visuals disappear and show the new stage visuals
func change_stage(new_stage: int) -> void:
	hide_all_stages.emit()
	stages[new_stage - 1].set_state(true)
	repair_time = stages[new_stage - 1].repair_time
	## If setting to damaged, enable collisions.
	if new_stage > 1:
		collision_layer = struct_collision_layer
	## Else, disable collisions
	else:
		collision_layer = 0


func play_sound() -> void:
	audio_player.play()


func setup() -> void:
	print(name, " set up.")
	## Set default structure properties
	collision_layer = 0
	collision_mask = 0
	## Clear connections
	var connections: Array = hide_all_stages.get_connections()
	for connection in connections:
		hide_all_stages.disconnect(connection["callable"])
	## Clear previous stages
	if stage_holder:
		stage_holder.free()
	stages.clear()
	## Create new stage holder
	stage_holder = Node3D.new()
	add_child(stage_holder)
	stage_holder.owner = self
	stage_holder.name = "StageHolder"
	## Create new stages
	for i in max_stage:
		add_stage()
		max_stage -= 1
	## Set visibility
	hide_all_stages.emit()
	stages[active_stage - 1].set_state(true)


func add_stage() -> void:
		if stage_holder == null:
			setup()
		var new_stage := MechStructStage.new()
		stage_holder.add_child(new_stage)
		hide_all_stages.connect(new_stage._on_hide_all_stages, CONNECT_PERSIST)
		new_stage.owner = self
		stages.append(new_stage)
		var stage_index: int = stages.size()
		new_stage.name = "Stage" + str(stage_index)
		new_stage.set_state(false)
		max_stage += 1


func remove_stage() -> void:
	if stage_holder == null:
		printerr("Cannot remove Stage from a Structure that hasn't been set up.")
		return
	if max_stage <= 2:
		print("Cannot go below 2 stages.")
		return
	var last_stage: MechStructStage = stages[-1]
	stages.erase(last_stage)
	last_stage.free()
	max_stage -= 1
