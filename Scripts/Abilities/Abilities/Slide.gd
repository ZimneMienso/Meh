class_name Slide
extends CharacterAction


func action_process(_delta: float) -> void:
	pass


func action_physics_process(delta: float) -> void:
	if Input.is_action_pressed("Slide") and player.is_on_floor2():
		attempt_action()
	else:
		stop_performing_action()


func ready() -> void:
	type = TYPES.SLIDE
	super()
