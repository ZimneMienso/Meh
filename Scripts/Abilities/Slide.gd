class_name Slide
extends CharacterAction


## Called every _process tick of the player
func action_process(_delta: float) -> void:
	pass


## Called every _physics_process tick of the player
func action_physics_process(delta: float) -> void:

	## Ignore manual input for sliding if not on the floor
	if not player.is_on_floor():
		stop_performing_action()
		return

	## Get relevant attributes
	var force_slide_slope_angle: float = \
	player.get_attribute(Attribute.TYPE.FORCE_SLIDE_SLOPE_ANGLE)
	var constant_slide_friction: float = \
	player.get_attribute(Attribute.TYPE.CONSTANT_SLIDE_FRICTION)
	
	## Attempt if keybind pressed and moving, or if slide is forced, otherwise
	## stop performing
	if Input.is_action_pressed("Slide") and player.velocity.z != 0 or \
	player.get_floor_angle() > force_slide_slope_angle:
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

	if slope_normal == -player.get_gravity().normalized():
		return ## Don't accelerate if on a flat surface
	
	## Apply gravity proportional to the slope angle
	var floor_angle: float = slope_normal.angle_to(Vector3.UP)
	var slope_gravity_acceleration_z: float = \
	player.get_gravity().length() * floor_angle * delta * slope_direction
	player.velocity.z += slope_gravity_acceleration_z
	
	


## Called on equiping
func ready() -> void:
	type = TYPES.SLIDE
	super()
