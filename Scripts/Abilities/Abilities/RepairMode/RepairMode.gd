class_name RepairMode
extends CharacterAction

# TODO Better hit detection
@export var trigger: AbilitySettingKeybind
@export var trigger_slowmo: AbilitySettingBool
@export var damage_detector_scene: PackedScene
@export var target_marker_scene: PackedScene
@export_range(0.1, 1, 0.01, "or_greater") var struct_scan_period: float = 0.5
## Key is marked body, value is marker.
var marked_targets: Dictionary[Node3D, TargetMarker]
var damage_detector: Area3D
var scan_timer: Timer


## Input events passed from the player
func action_input(event: InputEvent):
	if not event.is_action_pressed(trigger.action_name):
		return
	if Input.is_action_just_pressed(trigger.action_name):
		if performing:
			stop_performing_action()
		else:
			attempt_action()
	


## Called every _process tick of the player
func action_process(_delta: float) -> void:
	pass


## Called every _physics_process tick of the player
func action_physics_process(_delta: float) -> void:
	if performing:
		pass


func start_performing_action() -> void:
	super()
	if trigger_slowmo.get_value():
		player.send_ability_request(CharacterAction.TYPES.SLOW_MOTION, [true, 1])
	damage_detector.body_entered.connect(mark_target)
	damage_detector.body_exited.connect(unmark_target)
	scan_for_targets()
	scan_timer.start()


func stop_performing_action() -> void:
	super()
	if trigger_slowmo.get_value():
		player.send_ability_request(CharacterAction.TYPES.SLOW_MOTION, [false, 1])
	damage_detector.body_entered.disconnect(mark_target)
	damage_detector.body_exited.disconnect(unmark_target)
	clear_marked_targets()
	scan_timer.stop()


## Called on equiping
func ready() -> void:
	type = TYPES.REPAIR_MODE
	super()
	damage_detector = damage_detector_scene.instantiate()
	add_ability_object(damage_detector)
	scan_timer = Timer.new()
	scan_timer.wait_time = struct_scan_period
	scan_timer.ignore_time_scale = true
	add_ability_object(scan_timer)
	scan_timer.timeout.connect(scan_for_targets)


func mark_target(target: Node3D) -> void:
	var target_marker: TargetMarker = target_marker_scene.instantiate()
	target.add_child(target_marker)
	var aabb: AABB = (target as MechStruct).get_aabb()
	target_marker.scale = Vector3(1, 1, 1) * maxf(aabb.size.x, aabb.size.z)
	target_marker.lock_on()
	marked_targets.set(target, target_marker)


func unmark_target(target: Node3D) -> void:
	if not marked_targets.has(target):
		return
	marked_targets[target].lock_off()
	marked_targets.erase(target)


func clear_marked_targets() -> void:
	for target in marked_targets:
		marked_targets[target].lock_off()
	marked_targets.clear()


## Additional scan to fill in when body_entered signal lacks.
func scan_for_targets() -> void:
	var targets: Array[Node3D] = damage_detector.get_overlapping_bodies()
	for target in targets:
		if marked_targets.has(target):
			continue
		mark_target(target)
