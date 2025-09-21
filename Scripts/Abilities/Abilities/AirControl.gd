class_name AirControl
extends CharacterAction

## Acceleration multiplier when trying to move
## in the opposite direction to velocity.
@export var deceleration_bonus_acceleration: float
@export var precision_mode_max_velocity: float
@export var precision_mode_bonus_acceleration: float

var input_vector: Vector2


## Called every _process tick of the player
func action_process(_delta: float) -> void:
	input_vector = player.input_vector
	if player.is_in_air() and (input_vector.x != 0 or input_vector.y < 0):
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

		## Do the thing
		## Moving in the opposite direction to velocity
		if sign(player.velocity.z) != sign(input_vector.x) and player.velocity.z != 0:
			player.velocity.z += \
			(air_acceleration + deceleration_bonus_acceleration) * \
			input_vector.x * delta
		## Moving in the same direction as velocity below precision mode limit
		elif abs(player.velocity.z) <= precision_mode_max_velocity:
			player.velocity.z += \
			(air_acceleration + precision_mode_bonus_acceleration) * \
			input_vector.x  * delta
		## Moving in the same direction as velocity while below max speed
		elif abs(player.velocity.z) <= air_control_max_velocity:
			player.velocity.z += \
			air_acceleration * input_vector.x  * delta

		## Fast fall
		if input_vector.y < 0:
			player.velocity.y -= delta * \
			(air_acceleration + precision_mode_bonus_acceleration)



## Called on equiping
func ready() -> void:
	type = TYPES.AIR_CONTROL
	super()
