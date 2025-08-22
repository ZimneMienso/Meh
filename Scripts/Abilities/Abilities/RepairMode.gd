class_name RepairMode
extends CharacterAction


@export var trigger_slowmo: AbilitySettingBool


## Input events passed from the player
func action_input(event: InputEvent):
	if not event.is_action_pressed(ability_name):
		return
	if Input.is_action_just_pressed(ability_name):
		if performing:
			stop_performing_action()
		else:
			start_performing_action()
	


## Called every _process tick of the player
func action_process(_delta: float) -> void:
	pass


## Called every _physics_process tick of the player
func action_physics_process(_delta: float) -> void:
	if performing:
		pass


func start_performing_action() -> void:
	super()
	if trigger_slowmo.get_value():
		player.send_ability_request(CharacterAction.TYPES.SLOW_MOTION, [true, 1])


func stop_performing_action() -> void:
	super()
	if trigger_slowmo.get_value():
		player.send_ability_request(CharacterAction.TYPES.SLOW_MOTION, [false])


## Called on equiping
func ready() -> void:
	type = TYPES.REPAIR_MODE
	super()
