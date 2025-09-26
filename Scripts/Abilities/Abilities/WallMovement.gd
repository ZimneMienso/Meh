## Allows deceleration in both directions while snapped to a wall, acceleration down the wall
## and jumping either 45° up and away from the wall
## If input on the z axis is directed away from the wall, the jump vector is perpendicular to it,
## while also redirecting momentum towards that vector.
class_name WallMovement
extends CharacterAction


## The fraction of speed lost every second while manually decelerating.
@export_range(0, 10, 0.1) var friction_factor: float = 5
## The velocity added by the jump.
@export_range(0, 100, 0.1, "or_greater") var jump_impulse: float = 16
@export_range(0, 90, 0.1, "radians_as_degrees") var jump_angle: float = deg_to_rad(20)


## Called every _process tick of the player
func action_process(_delta: float) -> void:
	pass


## Called every _physics_process tick of the player
func action_physics_process(delta: float) -> void:
	if player.collision_state == player.COLLISION_STATES.WALL:
		attempt_action()
	else:
		stop_performing_action()
		return
		
	if performing:
		var wall_normal: Vector3 = player.last_slide_collision.get_collision_normal()
		wall_slide_friction(wall_normal, delta)
		if Input.is_action_just_pressed("Jump"):
			wall_jump(wall_normal)


func wall_slide_friction(normal: Vector3, delta: float) -> void:
	if player.input_vector3 == Vector3.ZERO:
		return
	var up_wall_direction: Vector3 = \
	normal.rotated(Vector3.RIGHT, -PI/2 * signf(normal.z)).normalized()
	var speed_up_wall: float = HF.get_speed_in_direction(up_wall_direction, player.velocity)
	var input_vector: Vector3 = player.input_vector3
	## If the input points in the opposite direction to the velocity along wall, apply friction.
	if (input_vector.y and signf(input_vector.y) != signf(speed_up_wall)):
			player.velocity -= speed_up_wall * friction_factor * up_wall_direction * delta
		## If no relevant input, let gravity do it's thing.


func wall_jump(normal: Vector3) -> void:
	## If the input points away from the wall on z axis, redirect velocity towads the normal.
	if player.input_vector3.z and signf(player.input_vector3.z) == signf(normal.z):
		player.velocity = maxf(player.velocity.length(), jump_impulse) * normal
		return
	## If the input vector points up on y axis or is 0, jump away from the wall,
	## an angle off up vector.
	var jump_vector: Vector3
	if player.input_vector3.y >= 0:
		player.velocity.y = maxf(0, player.velocity.y)
		jump_vector = Vector3.UP.rotated(Vector3.RIGHT, jump_angle * signf(normal.z)).normalized()
		jump_vector *= jump_impulse
		player.velocity.z += jump_vector.z
		player.velocity.y += maxf(0, jump_vector.y - player.velocity.y) 
	## Otherwise (negative y input) jump away from the wall, an angle off the down vector.
	else:
		player.velocity.y = minf(0, player.velocity.y)
		jump_vector = Vector3.DOWN.rotated(Vector3.RIGHT, -jump_angle * signf(normal.z)).normalized()
		jump_vector *= jump_impulse
		player.velocity.z += jump_vector.z
		player.velocity.y += minf(0, jump_vector.y - player.velocity.y) 


## Called on equiping
func ready() -> void:
	type = TYPES.WALL_MOVEMENT
	super()
