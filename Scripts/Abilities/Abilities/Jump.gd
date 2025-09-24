class_name Jump
extends CharacterAction


@export_range(0, 1, 0.01, "or_greater") var cooldown: float
var cooldown_progress: float = 0

@export_range(0, 1, 0.01, "or_greater") var coyote_time_duration: float
var coyote_time: float = 0
var slide_jump_contact_point: PhysicsTestMotionResult3D = null

@export_range(0, 90, 0.1, "radians_as_degrees") var minimum_slope_jump_angle: float =  deg_to_rad(35)

## Passed down from the player
func action_input(event: InputEvent) -> void:
	if event.is_action("Jump") and cooldown_progress == 0 and slide_jump_contact_point:
		attempt_action()


## Called every _physics_process tick of the player
func action_physics_process(delta: float) -> void:
	if cooldown_progress:
		cooldown_progress = max(0, cooldown_progress - delta)

	if player.is_on_floor2() and cooldown_progress == 0:
		coyote_time = coyote_time_duration
		if player.last_slide_collision:
			slide_jump_contact_point = player.last_slide_collision
	else:
		coyote_time = coyote_time - delta
		if coyote_time <= 0:
			slide_jump_contact_point = null


func start_performing_action() -> void:
	super()
	cooldown_progress = cooldown
	coyote_time = 0
	player.velocity += player.get_attribute(Attribute.TYPE.JUMP_IMPULSE) * Vector3.UP

	attempt_slide_jump()
	stop_performing_action()


func attempt_slide_jump() -> void:
	if player.active_abilities.has(TYPES.SLIDE) and \
	slide_jump_contact_point.get_collision_normal().angle_to(Vector3.UP) > \
	minimum_slope_jump_angle and \
	signf(player.input_vector3.z) == signf(slide_jump_contact_point.get_collision_normal().z):
		player.velocity = player.velocity.length() * slide_jump_contact_point.get_collision_normal()


## Called on equiping
func ready() -> void:
	type = TYPES.JUMP
	super()
