class_name Run
extends CharacterAction

@export var precision_mode_max_velocity: float
@export var precision_mode_bonus_acceleration: float

var input_axis: float

func action_process(_delta: float) -> void:
	input_axis = Input.get_axis("Move Right", "Move Left")
	if player.is_on_floor() and input_axis != 0:
		attempt_action()
	else:
		stop_performing_action()


## Called every _physics_process tick of the player
func action_physics_process(delta: float) -> void:
	if performing:

		## Get relevant attributes
		var run_max_speed: float = \
		player.get_attribute(Attribute.TYPE.RUN_MAX_SPEED)
		var run_acceleration: float = \
		player.get_attribute(Attribute.TYPE.RUN_ACCELERATION)
		var forced_grounded_stop_acceleration_bonus: float = \
		player.get_attribute(Attribute.TYPE.FORCED_GROUND_STOP_ACCELERATION_BONUS)

		## Do the thing
		## First check if player forces a grounded stop
		if player.velocity.z != 0 and sign(player.velocity.z) != sign(input_axis):
			player.velocity.z += \
			(run_acceleration + forced_grounded_stop_acceleration_bonus) * \
			input_axis * delta

		## In not, pick between precision and normal mode based on current velocity
		elif abs(player.velocity.z) <= precision_mode_max_velocity:
			player.velocity.z += \
			(run_acceleration + precision_mode_bonus_acceleration) * \
			input_axis * delta

		elif abs(player.velocity.z) <= run_max_speed:
			player.velocity.z += run_acceleration * input_axis * delta
		player.anim_player.play(player.anim_name_run)


## Called on equiping
func ready() -> void:
	type = TYPES.RUN
	super()
