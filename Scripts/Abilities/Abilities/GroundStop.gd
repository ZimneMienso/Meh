class_name GroundStop
extends CharacterAction

## Called every _process tick of the player
func action_process(_delta: float) -> void:
	pass


## Called every _physics_process tick of the player
func action_physics_process(delta: float) -> void:
	if player.is_on_floor():
		attempt_action()
	else:
		stop_performing_action()
	
	if performing:
		var ground_stop_friction: float = \
		player.get_attribute(Attribute.TYPE.GROUND_STOP_FRICTION)
		
		player.velocity.z = Player.apply_constant_friction(
			delta, player.velocity.z, ground_stop_friction)
		player.anim_player.play(player.anim_name_idle)


## Called on equiping
func ready() -> void:
	type = TYPES.GROUNDED_STOP
	super()
