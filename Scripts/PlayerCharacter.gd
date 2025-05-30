extends CharacterBody3D
class_name Player

@onready var anim_player: AnimationPlayer = $CharacterPlaceholder/AnimationPlayer

@export_category("Grounded Movement")
@export_range(0, 30, 0.1, "or_greater") var run_max_speed: float = 7
@export_range(0, 500, 0.1, "or_greater") var run_acceleration: float = 100
@export_range(0, 500, 0.1, "or_greater") var ground_stop_friction: float = 300
@export_category("Jump")
@export_range(0, 100, 0.1, "or_greater") var jump_impulse: float = 10
@export_range(0, 100, 0.1, "or_greater") var max_jump_velocity: float = 10
@export_category("Air Control")
@export_range(0, 30, 0.1, "or_greater") var air_acceleration: float = 4
@export_range(0, 30, 0.1, "or_greater") var air_control_max_velocity: float = 7
@export_range(0, 5, 0.1, "or_greater") var air_friction: float = 0.1
@export_category("Slide")
## Applied to the sliding character at all times
@export_range(0, 5, 0.1, "or_greater") var constant_slide_friction: float = 0.5
## Slope angle above which the character is forced into slide
@export_range(0, 90, 1, "radians_as_degrees") var force_slide_slope_angle: float = 0.5
@export_category("Grappling Hook")
@export_range(0, 100, 0.1, "or_greater") var grappling_hook_range: float = 20
@export_range(0, 100, 0.1, "or_greater") var grappling_hook_speed: float = 20
@export_category("Other")


enum CHAR_ACTIONS {
	GROUNDED_STOP,
	RUN,
	JUMP,
	AIR_CONTROL,
	FREEFALL,
	SLIDE,
	ROCKET_ENGINE,
	GRAPPLING_HOOK
}

const anim_name_idle: String = "Armature|Idle"
const anim_name_run: String = "Armature|Run"

var using_rocket_engine: bool = false


func _ready() -> void:
	CAMERAMAN.tracking = self


func _physics_process(delta: float) -> void:
	var input_vector = Input.get_vector("Move Right","Move Left","Move Down","Move Up")
	var character_action_requests: Array[int] = get_player_action_requests(input_vector)
	manage_character_actions(delta, character_action_requests, input_vector)

	velocity += delta * get_gravity()
	apply_grappling_hook_swing()
	move_and_slide()
	align_rotation_with_velocity()
	debug_update_stats_label(character_action_requests)


func align_rotation_with_velocity():
	rotation.y = deg_to_rad(-sign(velocity.z) * 90 + 90)

#region Character Actions


func get_player_action_requests(input_vector: Vector2) -> Array[int]:
	var character_action_requests: Array[int]
	if Input.is_action_just_pressed("Use Rocket Engine"):
		using_rocket_engine = not using_rocket_engine
	if using_rocket_engine:
		character_action_requests.append(CHAR_ACTIONS.ROCKET_ENGINE)
	
	if Input.is_action_just_pressed("Use Grappling Hook"):
		character_action_requests.append(CHAR_ACTIONS.GRAPPLING_HOOK)

	if is_on_floor():
		if Input.is_action_pressed("Jump"):
			character_action_requests.append(CHAR_ACTIONS.JUMP)

		if Input.is_action_pressed("Slide") or get_floor_angle() > force_slide_slope_angle or using_rocket_engine:
			character_action_requests.append(CHAR_ACTIONS.SLIDE)
			return character_action_requests ## Ignore run and other grounded movement

		## Everything after is ignored if sliding
		if input_vector.x != 0:
			character_action_requests.append(CHAR_ACTIONS.RUN)

		if input_vector.x == 0:
			character_action_requests.append(CHAR_ACTIONS.GROUNDED_STOP)

	else:
		if input_vector.x != 0:
			character_action_requests.append(CHAR_ACTIONS.AIR_CONTROL)
			return character_action_requests ## Ignore freefall check

		if character_action_requests == []:
			character_action_requests.append(CHAR_ACTIONS.FREEFALL)

	return character_action_requests


func manage_character_actions(delta: float, character_action_requests: Array[int], input_vector: Vector2):
	for character_action in character_action_requests:
		match character_action:
			CHAR_ACTIONS.GROUNDED_STOP:
				grounded_stop(delta)
			CHAR_ACTIONS.RUN:
				run(delta, input_vector.x)
			CHAR_ACTIONS.JUMP:
				jump()
			CHAR_ACTIONS.AIR_CONTROL:
				air_control(delta, input_vector.x)
			CHAR_ACTIONS.FREEFALL:
				freefall(delta)
			CHAR_ACTIONS.SLIDE:
				slide(delta)
			CHAR_ACTIONS.ROCKET_ENGINE:
				use_rocket_engine(delta)
			CHAR_ACTIONS.GRAPPLING_HOOK:
				use_grappling_hook()


func run(delta: float, input_vector_x: float):
	if abs(velocity.z) <= run_max_speed or sign(velocity.z) != sign(input_vector_x):
		velocity.z += run_acceleration * input_vector_x * delta
	anim_player.play(anim_name_run)


func grounded_stop(delta):
	velocity.z = apply_constant_friction(delta, velocity.z, ground_stop_friction)
	anim_player.play(anim_name_idle)


func jump():
	velocity.y += jump_impulse


func air_control(delta: float, input_vector_x: float):
	if abs(velocity.z) <= air_control_max_velocity or sign(velocity.z) != sign(input_vector_x):
		velocity.z += air_acceleration * input_vector_x  * delta
	if abs(velocity.z) > air_control_max_velocity:
		velocity.z = apply_constant_friction(delta, velocity.z, air_friction)


func freefall(delta: float):
	anim_player.play("Armature|BasePose")
	velocity.z = apply_constant_friction(delta, velocity.z, air_friction)


func slide(delta: float):
	if velocity.z != 0:
		anim_player.play("Armature|BasePose")
		
	if abs(velocity.z) > run_max_speed:
		velocity.z = apply_constant_friction(delta, velocity.z, constant_slide_friction)

	var slope_normal: Vector3 = get_floor_normal()
	var slope_direction: float = sign(slope_normal.z)

	if slope_normal == -get_gravity().normalized():
		return ## Don't accelerate if on a flat surface
	
	var floor_angle: float = slope_normal.angle_to(Vector3.UP)
	var slope_gravity_acceleration_z: float = get_gravity().length() * floor_angle * delta * slope_direction
	velocity.z += slope_gravity_acceleration_z


func use_rocket_engine(delta: float):
	velocity += velocity.normalized() * delta * 20
	$RocketEngineParticles.emitting = true


func use_grappling_hook():
	if not hook_attachments.is_empty():
		hook_attachments.clear()
	
	# Curson projector on world 3000
	var viewport: Viewport = get_viewport()
	var camera: Camera3D = viewport.get_camera_3d()
	var mouse_pos: Vector2 = viewport.get_mouse_position()
	var projection_origin: Vector3 = camera.project_ray_origin(mouse_pos)
	var projection_direction: Vector3 = camera.project_ray_normal(mouse_pos)
	var projection_distance: float = -projection_origin.x / projection_direction.x
	var mouse_projection: Vector3 = projection_origin + projection_direction * projection_distance
	
	var hook_lifetime: float = grappling_hook_range / grappling_hook_speed

	var hook_placeholder: RigidBody3D = RigidBody3D.new()
	hook_placeholder.gravity_scale = 0
	hook_placeholder.collision_layer = 0
	hook_placeholder.contact_monitor = true
	hook_placeholder.max_contacts_reported = 1
	var hook_placeholder_mesh_instance: MeshInstance3D = MeshInstance3D.new()
	var hook_placeholder_mesh: SphereMesh = SphereMesh.new()
	hook_placeholder_mesh.height = 0.25
	hook_placeholder_mesh.radius = 0.125
	var hook_placeholder_mesh_material: StandardMaterial3D = StandardMaterial3D.new()
	hook_placeholder_mesh_material.albedo_color = Color(1,0,0)
	hook_placeholder_mesh_instance.mesh = hook_placeholder_mesh
	var hook_paceholder_collision_shape: CollisionShape3D = CollisionShape3D.new()
	var hook_placeholder_collision_shape_shape: SphereShape3D = SphereShape3D.new()
	hook_placeholder_collision_shape_shape.radius = 0.125
	hook_paceholder_collision_shape.shape = hook_placeholder_collision_shape_shape
	
	
	hook_placeholder.body_entered.connect(on_hook_projectile_collision.bind(hook_placeholder))
	hook_placeholder.body_entered.connect(hook_placeholder.queue_free.unbind(1))
	
	get_parent().add_child(hook_placeholder)
	
	var timer: Timer = Timer.new()
	hook_placeholder.add_child(timer)
	timer.timeout.connect(hook_placeholder.queue_free)
	timer.start(hook_lifetime)
	
	hook_placeholder.global_position = global_position + Vector3.UP
	hook_placeholder.add_child(hook_placeholder_mesh_instance)
	hook_placeholder.add_child(hook_paceholder_collision_shape)
	hook_placeholder.linear_velocity = (mouse_projection - Vector3.UP - global_position).normalized() * grappling_hook_speed

#endregion Character Actions

#region Grappling Hook
var hook_attach_point_debug: MeshInstance3D

class HookAttachment:
	extends Node3D
	var hook_distance: float

var hook_attachments: Array[HookAttachment]


func on_hook_projectile_collision(hit_collider: Node3D, hook_placeholder: RigidBody3D):
	attach_grappling_hook(hit_collider, hook_placeholder.global_position)


func attach_grappling_hook(attach_to: Node3D, hook_position: Vector3):
	hook_attach_point_debug = MeshInstance3D.new()
	hook_attach_point_debug.mesh = SphereMesh.new()
	hook_attach_point_debug.mesh.radius = 0.2
	hook_attach_point_debug.mesh.height = 0.4
	
	var new_hook_attachment: HookAttachment = HookAttachment.new()
	hook_attachments.append(new_hook_attachment)
	attach_to.add_child(new_hook_attachment)
	new_hook_attachment.global_position = hook_position
	new_hook_attachment.global_position.x = 0
	new_hook_attachment.hook_distance = (global_position - hook_position).length()
	
	new_hook_attachment.add_child(hook_attach_point_debug)


func apply_grappling_hook_swing():
	

	if hook_attachments.is_empty():
		return

	var last_attachment: HookAttachment = hook_attachments[-1]

	#if global_position.distance_to(last_attachment.global_position) <= last_attachment.hook_distance:
	#	return
	
	var nearest_point_on_circle: Vector3 = \
	last_attachment.global_position.direction_to(global_position) * \
	last_attachment.hook_distance + last_attachment.global_position

	var tangent_left: Vector3 = (last_attachment.to_local(nearest_point_on_circle)).cross(Vector3.LEFT).normalized()
	var tangent_right: Vector3 = (last_attachment.to_local(nearest_point_on_circle)).cross(Vector3.RIGHT).normalized()


	
#endregion Grappling Hook


static func apply_constant_friction(delta: float, value: float, friction: float) -> float:
	return move_toward(value, 0, friction * delta)


func debug_update_stats_label(player_actions: Array[int]):
	var text: String = \
	"
	Velocity = %s
	Actions = %s
	"
	var player_action_text_converter = func() -> Array[String]:
		var result: Array[String]
		for i in player_actions.size():
			result.append(CHAR_ACTIONS.find_key(player_actions[i]))
		return result
	
	var player_actions_text: Array[String] = player_action_text_converter.call()
	
	$StatsLabel.text = text % [velocity.round(), player_actions_text, ]


func _on_tag_filter_button_pressed() -> void:
	pass # Replace with function body.
