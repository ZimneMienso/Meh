class_name Welder
extends CharacterAction

@export var welder_scene: PackedScene
## The time between hits
@export var hit_period: float = 0.2
## How much does it repair per shot
@export var repair_value: float = 0.5
@export var trigger: AbilitySettingKeybind

var welder_instance: Node3D
var sprite: AnimatedSprite3D
var collider: Area3D
var timer: Timer


## Input events passed from the player
func action_input(event: InputEvent) -> void:
	if not event.is_action(trigger.action_name):
		return
	if Input.is_action_pressed(trigger.action_name):
			attempt_action()
	if Input.is_action_just_released(trigger.action_name):
			stop_performing_action()
	player.get_viewport().set_input_as_handled()


## Called every _process tick of the player
func action_process(_delta: float) -> void:
	pass


## Called every _physics_process tick of the player
func action_physics_process(_delta: float) -> void:
	if performing:
		welder_instance.look_at_from_position(
			player.global_position + Vector3.UP,
			HF.project_cursor_on_world(player.get_viewport()),
			Vector3.RIGHT
			)


func start_performing_action() -> void:
	super()
	welder_instance.show()
	# TODO make sure this affects the timer in the welder scene.
	welder_instance.process_mode = Node.PROCESS_MODE_INHERIT
	sprite.play()
	timer.wait_time = hit_period
	timer.start()


func stop_performing_action() -> void:
	super()
	welder_instance.hide()
	welder_instance.process_mode = Node.PROCESS_MODE_DISABLED


## Called on equiping
func ready() -> void:
	type = TYPES.WELDER
	super()
	
	welder_instance = welder_scene.instantiate()
	add_ability_object(welder_instance)
	welder_instance.hide()
	sprite = welder_instance.get_node("FlameSprite") as AnimatedSprite3D
	collider = welder_instance.get_node("Area3D") as Area3D
	timer = welder_instance.get_node("Timer") as Timer
	timer.timeout.connect(check_for_mech_struct_hits)


func check_for_mech_struct_hits() -> void:
	var hits: Array[MechStruct]
	hits.assign(collider.get_overlapping_bodies())
	for hit in hits:
		hit.receive_repair(repair_value)
