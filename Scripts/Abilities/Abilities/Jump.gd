class_name Jump
extends CharacterAction

@export_range(0, 1, 0.01, "or_greater") var cooldown: float
var cooldown_progress: float = 0

## Called every _process tick of the player
func action_process(_delta: float) -> void:
	#if Input.is_action_pressed("Jump") and (player.is_on_floor() or player.get_coyote_time()):
	if Input.is_action_pressed("Jump") and cooldown_progress == 0 and \
	(player.is_on_floor() or player.get_coyote_time()):
		attempt_action()


## Called every _physics_process tick of the player
func action_physics_process(delta: float) -> void:
	if cooldown_progress:
		cooldown_progress = max(0, cooldown_progress - delta)
	if performing:
		player.velocity.y += player.get_attribute(Attribute.TYPE.JUMP_IMPULSE)
		stop_performing_action()


func start_performing_action() -> void:
	super()
	cooldown_progress = cooldown


## Called on equiping
func ready() -> void:
	type = TYPES.JUMP
	super()
