class_name GrapplingHook
extends CharacterAction

# TODO Fix the swing stabilizing at weird angles
# TODO Make the "projectile" raycast-based
# TODO Add bending
# TODO Limit the position corrcetion to avoid ending up in walls

@export var trigger: AbilitySettingKeybind

@export var hook_projectile: RayProjectileEmitter
@export var hook_range: float
@export var hook_speed: float
var hook_lifetime: float

var rope_immediate_mesh: MeshInstance3D
var active_hook_projectile: Node3D
var rope_mesh_material: ORMMaterial3D

var swing_direction: float

class HookAttachment:
	extends Node3D
	## The remaining amount of rope
	var rope_lenght: float

var hook_attachments: Array[HookAttachment]


func action_input(event: InputEvent) -> void:
	if event.is_action(trigger.action_name):
		if Input.is_action_just_pressed(trigger.action_name):
			if performing:
				stop_performing_action()
			else:
				attempt_action()

	if event.is_action("Jump") and hook_attachments.size() > 0: 
			stop_performing_action()


## Called every _process tick of the player
func action_process(_delta: float) -> void:
	## Drawing the "rope"
	if hook_attachments or active_hook_projectile:
		const player_pos_offset: Vector3 = Vector3.UP
		rope_immediate_mesh.mesh.clear_surfaces()
		rope_immediate_mesh.mesh.surface_begin(
			Mesh.PRIMITIVE_LINES, rope_mesh_material)

		if hook_attachments:
			var last_attachment_pos: Vector3 = \
				hook_attachments[-1].global_position
			rope_immediate_mesh.mesh.surface_add_vertex(
				last_attachment_pos)
		else:
			rope_immediate_mesh.mesh.surface_add_vertex(
				active_hook_projectile.global_position)

		rope_immediate_mesh.mesh.surface_add_vertex(
			player.global_position + player_pos_offset)
		rope_immediate_mesh.mesh.surface_end()


## Called every _physics_process tick of the player
func action_physics_process(_delta: float) -> void:
	if not performing:
		return
	if not hook_attachments:
		return
	var last_attachment: HookAttachment = hook_attachments[-1]
	var last_attachment_pos: Vector2 = HF.v3_to_v2(last_attachment.global_position)
	
	if last_attachment_pos.distance_to(HF.v3_to_v2(player.global_position)) < \
	last_attachment.rope_lenght:
		return

	var max_lenght_rope_endpoint: Vector2 = \
	last_attachment_pos.direction_to(HF.v3_to_v2(player.global_position)) * \
		last_attachment.rope_lenght + last_attachment_pos

	var pos_in_relation_to_circle: Vector2 = \
	max_lenght_rope_endpoint - last_attachment_pos
	## The angle between position in circle space to velocity
	var position_to_velocity_angle: float = \
	pos_in_relation_to_circle.angle_to(HF.v3_to_v2(player.velocity))

	var angle_on_circle: float = \
	(HF.v3_to_v2(player.position) - last_attachment_pos).angle_to(Vector2.RIGHT)
	var velocity_rotated_by_angle_on_circle: Vector2 = \
	HF.v3_to_v2(player.velocity).rotated(angle_on_circle)
	
	if swing_direction == 0 and \
	# TODO Maybe move the deg to an exported var
	position_to_velocity_angle < deg_to_rad(20) and \
	player.input_vector:
		if player.input_vector.x:
			swing_direction = \
			sign(player.input_vector.x) * -sign(pos_in_relation_to_circle.y)
		else:
			swing_direction = \
			sign(player.input_vector.y) * sign(pos_in_relation_to_circle.x)
	else:
		swing_direction = sign(velocity_rotated_by_angle_on_circle.y)
	
	## This is in circle space
	var circle_tangent: Vector2 = pos_in_relation_to_circle.normalized().rotated(
		swing_direction * PI/2)
	var rotated_velocity: Vector2 = player.velocity.length() * circle_tangent
	var position_error: Vector3 = player.global_position - HF.v2_to_v3(
		max_lenght_rope_endpoint)
		
	player.velocity = HF.v2_to_v3(rotated_velocity)
	player.position -= position_error


## Called on equiping
func ready() -> void:
	type = TYPES.GRAPPLING_HOOK
	super()
	hook_lifetime = hook_range / hook_speed

	##Rope Drawing
	rope_immediate_mesh = MeshInstance3D.new()
	rope_immediate_mesh.mesh = ImmediateMesh.new()

	rope_mesh_material = ORMMaterial3D.new()
	rope_mesh_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rope_mesh_material.albedo_color = Color.BLACK

	add_ability_object(rope_immediate_mesh, player.get_tree().get_root())

	hook_projectile.projectile_hit.connect(_on_projectile_hit)


func start_performing_action():
	super()
	fire_hook_projectile()
	swing_direction = 0


func stop_performing_action():
	super()
	clear_attachments()
	rope_immediate_mesh.mesh.clear_surfaces()
	if active_hook_projectile:
		active_hook_projectile.queue_free()


func clear_attachments():
	for attachment in hook_attachments:
		attachment.queue_free()
	hook_attachments.clear()


func fire_hook_projectile() -> void:
	var target: Vector3 = HF.project_cursor_on_world(player.get_viewport())
	active_hook_projectile = hook_projectile.fire(
		player.get_parent(), player.global_position + Vector3.UP * 1, target)
	if not active_hook_projectile:
		stop_performing_action()


func on_hook_projectile_collision(
	hit_collider: Node3D, hook_placeholder: RigidBody3D
	):
	attach_grappling_hook(hit_collider, hook_placeholder.global_position)


func attach_grappling_hook(attach_to: Node3D, hook_position: Vector3):
	var hook_attach_point_debug: MeshInstance3D
	hook_attach_point_debug = MeshInstance3D.new()
	hook_attach_point_debug.mesh = SphereMesh.new()
	hook_attach_point_debug.mesh.radius = 0.2
	hook_attach_point_debug.mesh.height = 0.4
	
	var new_hook_attachment: HookAttachment = HookAttachment.new()
	attach_to.add_child(new_hook_attachment)
	new_hook_attachment.global_position = hook_position
	new_hook_attachment.global_position.x = 0
	new_hook_attachment.rope_lenght = \
	(player.global_position - hook_position).length()

	hook_attach_point_debug.scale *= 0.1 #TODO fix the stupid import
	new_hook_attachment.add_child(hook_attach_point_debug)
	hook_attachments.append(new_hook_attachment)


func _on_projectile_hit(hit_data: ProjectileEmitter.ProjHitData) -> void:
	## Check in case the shot is cancelled before it lands.
	if performing:
		attach_grappling_hook(hit_data.collider, hit_data.collision_pos)
