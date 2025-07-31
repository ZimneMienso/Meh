class_name RepairMode
extends CharacterAction



## Input events passed from the player
func action_input(event: InputEvent):
	if not event.is_action_pressed(ability_name):
		return
	if Input.is_action_just_pressed(ability_name):
		if performing:
			start_performing_action()
		else:
			stop_performing_action()
	


## Called every _process tick of the player
func action_process(_delta: float) -> void:
	pass


## Called every _physics_process tick of the player
func action_physics_process(_delta: float) -> void:
	if performing:
		pass


## Called on equiping
func ready() -> void:
	type = TYPES.REPAIR_MODE
	super()
