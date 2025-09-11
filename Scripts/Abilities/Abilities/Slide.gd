class_name Slide
extends CharacterAction

@export_category("Sliding")
## On collision at this or lower angle of attack, retain 100% of speed and
## redirect velocity along the surface. 
@export_range(0, 90, 1, "radians_as_degrees") var min_speed_retention_angle: float = deg_to_rad(45)
## On collision at this or greater angle of attack, cancel all velocity 
## towards the surface.
@export_range(0, 90, 1, "radians_as_degrees") var max_speed_retention_angle: float = deg_to_rad(75)

## The maximum distance surface snapping can attach. 
@export_category("Snapping")
@export_range(0, 5, 0.01, "or_greater") var snapping_lenght: float = 0
## The the magnitude of the velocity in the direction of the attached surface
## normal that will cause detachment from that surface.
@export_range(0, 5, 0.1, "or_greater") var snapping_detach_speed: float = 0
var snapping_direction: Vector3 = Vector3.ZERO
# This might end up being usused, watch out
var saved_floor_snap_length: float
## Is the player currently snapped to a surface.
#var snapping: bool = false
### How far does the player detach when unsnapping. Does not affect velocity. 
#@export_range(0, 1, 0.001, "or_greater") var snapping_safety_detach: float = 0
## The maximum angle between the snapping direction and input vector before unsnapping
const snapping_input_tolerance: float = deg_to_rad(95)





func action_process(_delta: float) -> void:
	pass


func action_physics_process(delta: float) -> void:

	#region Pre Universal Slide
	## Get relevant attributes
	var force_slide_slope_angle: float = \
	player.get_attribute(Attribute.TYPE.FORCE_SLIDE_SLOPE_ANGLE)
	var constant_slide_friction: float = \
	player.get_attribute(Attribute.TYPE.CONSTANT_SLIDE_FRICTION)
	
	## Attempt if keybind pressed and moving, or if slide is forced, otherwise
	## stop performing.

	## Must be on the floor
	if player.is_on_floor() and \
	## Is player forced to slide?
	(player.get_floor_angle() > deg_to_rad(force_slide_slope_angle) or \
	## Manual sliding input
	(Input.is_action_pressed("Slide") and player.velocity.z != 0)):
		attempt_action()
	else:
		stop_performing_action()


	
	if performing:

		## Apply friction
		player.velocity.z = \
		Player.apply_constant_friction(
			delta, player.velocity.z, constant_slide_friction
			)

	var slope_normal: Vector3 = player.get_floor_normal()
	var slope_direction: float = sign(slope_normal.z)

	# TODO don't forget to uncomment/rewrite this
	#if slope_normal == -player.get_gravity().normalized():
		#return ## Don't accelerate if on a flat surface
	
	## Apply gravity proportional to the slope angle
	var floor_angle: float = slope_normal.angle_to(Vector3.UP)
	var slope_gravity_acceleration_z: float = \
	player.get_gravity().length() * floor_angle * delta * slope_direction
	player.velocity.z += slope_gravity_acceleration_z
	#endregion Pre Universal Slide

	#region Universal Slide
	#var last_collision: KinematicCollision3D = player.get_last_slide_collision()
	#if not last_collision or not can_perform_action():
		#return
	#var previous_frame_collision: KinematicCollision3D = player.previous_frame_collision
	### Calculate the angle of attack
	#var velocity: Vector3 = player.last_frame_velocity
	#var normal: Vector3 = last_collision.get_normal()
	#var angle_of_attack: float = velocity.angle_to(normal) - PI/2
	### Check if the slide should redirect velocity.
	#if previous_frame_collision:
		##var prev_aoa: float = player.last_frame_velocity.angle_to(
			##previous_frame_collision.get_normal()) - PI/2
		##if prev_aoa < 0.1:
			##return
		#if absf(previous_frame_collision.get_angle() - last_collision.get_angle()) < 0.1:
			#if previous_frame_collision.get_angle() - last_collision.get_angle() > 0:
				#print("slide cancelled a", previous_frame_collision.get_angle() - last_collision.get_angle())
			#return
	### Decide the ratio of the portion of the velocity directed towards the surface
	### that will get redirected / lost depending on the angle of attack.
	#var speed_retention = clampf(remap(
		#angle_of_attack,
		#min_speed_retention_angle, 
		#max_speed_retention_angle,
		#1, 0), 0, 1)
	#var normal_angle: float = normal.signed_angle_to(Vector3.FORWARD, Vector3.RIGHT)
	### Velocity in a system in which the normal is the -z axis.
	#var zeroed_velocity: Vector3 = velocity.rotated(Vector3.RIGHT, normal_angle)
	#var speed_towards_surface: float = zeroed_velocity.z
	### Velocity NOT in the direction of the surface
	#var velocity_along_surface: Vector3 = \
	#Vector3(zeroed_velocity.x, zeroed_velocity.y, 0).rotated(Vector3.RIGHT, -normal_angle)
	#var final_velocity: Vector3 = \
	#velocity_along_surface + velocity_along_surface.normalized() * speed_retention
	#attempt_action()
	#player.velocity = final_velocity
	#if speed_retention < 1:
		#print("slide renention ", speed_retention)
	#player.temp_debug1.position = final_velocity.normalized() * 3
	#endregion Universal Slide


	#region Prediction Approach
	var collision: KinematicCollision3D = \
	player.move_and_collide(player.velocity * delta, true, player.safe_margin, true)
	var travel_this_frame: Vector3 = player.velocity * delta
	if collision:
		var velocity_remainder: Vector3 = travel_this_frame - collision.get_travel()

		var angle_of_attack: float = collision.get_normal().angle_to(player.velocity) - PI/2
		var speed_retention: float = clampf(remap(
			angle_of_attack,
			min_speed_retention_angle, 
			max_speed_retention_angle,
			1, 0), 0, 1)

		var collided_plane := Plane(collision.get_normal())
		var velocity_along_plane: Vector3 = collided_plane.project(
			velocity_remainder).normalized() * velocity_remainder.length()
		player.velocity = (collision.get_travel() + velocity_along_plane * speed_retention) / delta
	#endregion Prediction Approach

	#region Snapping
		snapping_direction = -collision.get_normal()

	## Check if snapping is desired at all.
	if snapping_lenght and snapping_direction and can_perform_action():
		## Perform a test move in the reverse direction of collided surface normal
		## up to the maximum snapping_lenght
		var snap_test: KinematicCollision3D = \
			player.move_and_collide(snapping_direction * snapping_lenght, true, player.safe_margin, true)
		## If the test move hit anything, the speed in the opposite direction is lower than
		## the snapping_detach_speed and player input vector is not pointing away from the surface,
		## snap to the surface.
		if snap_test and \
		HF.get_speed_in_direction(snap_test.get_normal(), player.velocity) < snapping_detach_speed and \
		player.input_vector3.angle_to(snapping_direction) < snapping_input_tolerance:
			player.global_position = player.global_position + snap_test.get_travel() - snap_test.get_travel().normalized() * player.safe_margin
			#snapping = true
		## Else, don't/stop snapping.
		else:
			#if snapping:
				#snapping = false
				#player.global_position = player.global_position - snapping_direction * snapping_safety_detach
			snapping_direction = Vector3.ZERO
	#endregion Snapping


func start_performing_action() -> void:
	saved_floor_snap_length = player.floor_snap_length
	player.floor_snap_length = 4
	super()


func stop_performing_action() -> void:
	player.floor_snap_length = saved_floor_snap_length
	super()


func ready() -> void:
	type = TYPES.SLIDE
	super()
