extends Node

static func translate_xy_to_zyx(coordinates: Vector2) -> Vector3:
	return Vector3(0, coordinates.y, coordinates.x)


## Returns the position in the world at the intersection of x = 0 plane and
## a ray projected from the camera.
func project_cursor_on_world(viewport: Viewport) -> Vector3:
	var camera: Camera3D = viewport.get_camera_3d()
	var mouse_pos: Vector2 = viewport.get_mouse_position()
	var projection_origin: Vector3 = camera.project_ray_origin(mouse_pos)
	var projection_direction: Vector3 = camera.project_ray_normal(mouse_pos)
	# No idea how it works and how I figured that out before
	var projection_distance: float = \
	-projection_origin.x / projection_direction.x
	var mouse_projection: Vector3 = \
	projection_origin + projection_direction * projection_distance
	return mouse_projection


# This should probably just be an equasion that outputs the distance to the
# point closest to the line in the direction of the direction vector, but I'm 
# feeling lazy today so.
func get_speed_in_direction(direction: Vector3, velocity: Vector3) -> float:
	#return velocity.rotated(
		#Vector3.RIGHT, direction.signed_angle_to(Vector3.UP, Vector3.RIGHT)).y
	return direction.dot(velocity) * velocity.length()


## Legacy shit used by grappling hook
func v3_to_v2(vector3: Vector3) -> Vector2:
	return Vector2(vector3.z, vector3.y)


func v2_to_v3(vector2: Vector2, x: float = 0) -> Vector3:
	return Vector3(x, vector2.y, vector2.x)
