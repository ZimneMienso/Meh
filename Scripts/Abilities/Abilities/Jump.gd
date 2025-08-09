class_name Jump
extends CharacterAction

## Called every _process tick of the player
func action_process(_delta: float) -> void:
	if Input.is_action_pressed("Jump") and player.is_on_floor():
		attempt_action()


## Called every _physics_process tick of the player
func action_physics_process(_delta: float) -> void:
	if performing:
		player.velocity.y += player.get_attribute(Attribute.TYPE.JUMP_IMPULSE)
		stop_performing_action()


## Called on equiping
func ready() -> void:
	type = TYPES.JUMP
	super()
