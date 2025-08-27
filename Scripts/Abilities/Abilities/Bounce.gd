class_name Bounce
extends CharacterAction

# TODO At least some contol
# TODO Velocity rollback

const reticle_scene: PackedScene = preload("res://Scenes/Abilities/bounce_reticle.tscn")
var reticle: Node3D

@export var delay_between_uses: float
var use_delay_progress: float = 0
@export var goo_ball_scene: PackedScene
var goo_ball_mesh: MeshInstance3D

@export var trigger: AbilitySettingKeybind
@export var choosing_bounce_direction: AbilitySettingKeybind
@export var autotrigger_slowmo: AbilitySettingBool
## The maximum deviation from natuaral bounce angle the player is allowed
## to make.
@export_range(0, 90, 1, "radians_as_degrees") var max_bounce_angle_influence: float
## Max time for the player to choose bounce direction between a collision and
## being bounce on a reflected vector. 
@export_range(0, 1, 0.01, "or_greater") var max_time_to_bounce: float = 0.5
var time_to_bounce: float = 0
var direction_chosen: bool = false

var bounce_velocity: Vector3


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
		## Waiting for a collision
		if time_to_bounce == 0:
			var last_slide_collision: KinematicCollision3D = \
			player.get_last_slide_collision()
			if last_slide_collision:
				bounce_velocity = calculate_bounce_velocity(
					player.last_frame_velocity,
					last_slide_collision.get_normal())
				time_to_bounce = max_time_to_bounce
				register_in_priority_input()
		## Bouncing
		if time_to_bounce > 0:
			## Decrease timer.
			time_to_bounce = max(0, time_to_bounce - delta)
			## Display angle reticle.
			reticle.show()
			reticle.global_position = player.global_position
			var angle_border_low: Node3D = reticle.get_child(0)
			var angle_border_high: Node3D = reticle.get_child(1)
			var angle_pointer: Node3D = reticle.get_child(2)
			var bounce_angle: float = bounce_velocity.signed_angle_to(Vector3.UP, Vector3.LEFT)
			var cursor_pos: Vector3 = HF.project_cursor_on_world(player.get_viewport())
			var angle_to_cursor_pos: float = \
			(cursor_pos - player.global_position).signed_angle_to(Vector3.UP, Vector3.LEFT)
			var max_angle: float = bounce_angle + max_bounce_angle_influence
			var min_angle: float = bounce_angle - max_bounce_angle_influence
			var pointer_angle: float = clampf(angle_to_cursor_pos, min_angle, max_angle)
			angle_border_high.rotation.x = max_angle
			angle_border_low.rotation.x = min_angle
			angle_pointer.rotation.x = pointer_angle
			### Immediately bounce if player chooses so.
			if direction_chosen:
				var cursor_3d_position: Vector3 = \
				HF.project_cursor_on_world(player.get_viewport())
				player.velocity = bounce_velocity
				direction_chosen = false
				time_to_bounce = 0
				reticle.hide()
			## Bounce if the bounce timer runs out.
			if time_to_bounce == 0:
				player.velocity = bounce_velocity
				player.priority_input_abilities.erase(self)
				time_to_bounce = 0
				reticle.hide()
			## Wait otherwise.
			else:
				player.velocity = Vector3.ZERO

		goo_ball_mesh.show()

	else:
		if use_delay_progress > 0:
			use_delay_progress = maxf(0, use_delay_progress - delta)


func stop_performing_action():
	super()
	use_delay_progress = delay_between_uses
	goo_ball_mesh.hide()
	reticle.hide()
	time_to_bounce = 0


## Called on equiping
func ready() -> void:
	type = TYPES.BOUNCE
	super()

	goo_ball_mesh = goo_ball_scene.instantiate()
	add_ability_object(goo_ball_mesh, player)
	goo_ball_mesh.hide()

	reticle = reticle_scene.instantiate()
	add_ability_object(reticle, player.get_tree().root)
	reticle.hide()


func process_priority_input(event: InputEvent) -> void:
	if event.is_action(choosing_bounce_direction.action_name):
		direction_chosen = true
		super(event)


static func calculate_bounce_velocity(velocity: Vector3, collider_normal: Vector3) -> Vector3:
	return velocity.bounce(collider_normal)
