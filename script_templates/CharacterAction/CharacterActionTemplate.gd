class_name _CLASS_
extends CharacterAction

# meta-name: Ability
# meta-default: true
# meta-space-indent: 4
## Called every _process tick of the player
func action_process(_delta: float) -> void:
#	if Input.is_action_just_pressed(ability_name):
#	if trigger:
#		attempt_action()
#	else:
#		stop_performing_action()
	pass


## Called every _physics_process tick of the player
func action_physics_process(_delta: float) -> void:
	if performing:
		pass


## Called on equiping
func ready() -> void:
	type = TYPES.NULL
	super()
