class_name Run
extends CharacterAction

var input_axis: float

func action_process(_delta: float) -> void:
	input_axis = Input.get_axis("Move Left", "Move Right")
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

		## Do the thing
		if abs(player.velocity.z) <= run_max_speed or sign(player.velocity.z) != sign(input_axis):
			player.velocity.z += run_acceleration * -input_axis * delta
		player.anim_player.play(player.anim_name_run)


## Called on equiping
func ready() -> void:
	type = TYPES.RUN
	super()
