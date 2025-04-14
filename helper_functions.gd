extends Node

static func translate_xy_to_zyx(coordinates: Vector2) -> Vector3:
	return Vector3(0, coordinates.y, coordinates.x)
