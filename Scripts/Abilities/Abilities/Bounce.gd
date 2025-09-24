class_name Bounce
extends CharacterAction

# TODO At least some contol
# TODO Velocity rollback

@export var delay_between_uses: float
var use_delay_progress: float = 0
@export var goo_ball_scene: PackedScene
var goo_ball_mesh: MeshInstance3D

@export var trigger: AbilitySettingKeybind

var just_activated: bool


func action_input(event: InputEvent) -> void:
	if not event.is_action(trigger.action_name):
		return
	if Input.is_action_just_pressed(trigger.action_name) and \
	use_delay_progress == 0 and not performing:
		attempt_action()
	elif Input.is_action_just_pressed(trigger.action_name) and performing:
		stop_performing_action()


## Called every _physics_process tick of the player
func action_physics_process(delta: float) -> void:
	if performing:
		var last_slide_collision: PhysicsTestMotionResult3D = \
		player.last_slide_collision
		if last_slide_collision:
			var collided_surface_normal: Vector3 = \
			last_slide_collision.get_collision_normal()
			bounce(player.last_frame_velocity, collided_surface_normal)

		goo_ball_mesh.show()

	else:
		if use_delay_progress > 0:
			use_delay_progress = maxf(0, use_delay_progress - delta)


func start_performing_action() -> void:
	super()
	var last_collision_rollback_event := player.get_velocity_rollback()
	if last_collision_rollback_event:
		bounce(
			last_collision_rollback_event.pre_collision_velocity,
			last_collision_rollback_event.collision.get_collision_normal()
		)
	player.collision_rollback_blockers.append(self)


func stop_performing_action() -> void:
	super()
	use_delay_progress = delay_between_uses
	goo_ball_mesh.hide()
	player.collision_rollback_blockers.erase(self)


## Called on equiping
func ready() -> void:
	type = TYPES.BOUNCE
	super()

	goo_ball_mesh = goo_ball_scene.instantiate()
	add_ability_object(goo_ball_mesh, player)
	goo_ball_mesh.hide()


func bounce(velocity: Vector3, normal: Vector3) -> void:
	player.velocity = velocity.bounce(normal)
