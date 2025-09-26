class_name Jump
extends CharacterAction


@export_range(0, 1, 0.01, "or_greater") var cooldown: float = 0.1
var cooldown_progress: float = 0

@export_range(0, 1, 0.01, "or_greater") var coyote_time_duration: float = 0.2
var coyote_time: float = 0

## Passed down from the player
func action_input(event: InputEvent) -> void:
	if event.is_action("Jump") and cooldown_progress == 0 and coyote_time:
		attempt_action()


## Called every _physics_process tick of the player
func action_physics_process(delta: float) -> void:
	if cooldown_progress:
		cooldown_progress = max(0, cooldown_progress - delta)

	if player.is_on_floor2() and cooldown_progress == 0:
		coyote_time = coyote_time_duration
	elif player.is_in_air():
		coyote_time = max(0, coyote_time - delta)
	else:
		coyote_time = 0


func start_performing_action() -> void:
	super()
	cooldown_progress = cooldown
	coyote_time = 0
	player.velocity += player.get_attribute(Attribute.TYPE.JUMP_IMPULSE) * Vector3.UP
	stop_performing_action()


## Called on equiping
func ready() -> void:
	type = TYPES.JUMP
	super()
