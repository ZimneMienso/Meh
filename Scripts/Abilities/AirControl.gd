class_name AirControl
extends CharacterAction

var input_axis: float


## Called every _process tick of the player
func action_process(delta: float) -> void:
	if player.is_on_floor():
		return
	input_axis = Input.get_axis("Move Left", "Move Right")
	if input_axis != 0:
		attempt_action()
	else:
		stop_performing_action()


## Called every _physics_process tick of the player
func action_physics_process(delta: float) -> void:
	if performing:

		## Get relevant attributes
		var air_control_max_velocity: float = \
		player.get_attribute(Attribute.TYPE.AIR_CONTROL_MAX_VELOCITY)
		var air_acceleration: float = \
		player.get_attribute(Attribute.TYPE.AIR_ACCELERATION)
		var air_friciton: float = \
		player.get_attribute(Attribute.TYPE.AIR_FRICTION)

		## Do the thing
		if abs(player.velocity.z) <= air_control_max_velocity or sign(player.velocity.z) != sign(input_axis):
			player.velocity.z += \
			air_acceleration * input_axis  * delta
		if abs(player.velocity.z) > air_control_max_velocity:
			player.velocity.z = \
			player.apply_constant_friction(delta, player.velocity.z, air_friciton)


## Called on equiping
func ready() -> void:
	type = TYPES.AIR_CONTROL
	super()
