class_name SlowMotion
extends CharacterAction

# TODO Adaptive, speed-dependent slow?

## Used as at a rate of 1/"normal" speed (Engine.time_scale == 1) second to 
## sustain the ability
@export var max_stored_slow: float
var stored_slow: float
## How much stored slow regenerates per second while the ability is off
@export var slow_regen: float
## By how much the game slows during the ability
@export_range(0, 0.9, 0.01) var slow: float


func action_input(event: InputEvent) -> void:
	if not event.is_action(ability_name):
		return
	if Input.is_action_just_pressed(ability_name):
		if performing:
			stop_performing_action()
		elif stored_slow > 0.1:
			start_performing_action()


## Called every _physics_process tick of the player
func action_physics_process(delta: float) -> void:
	if performing:
		stored_slow -= delta
		if stored_slow <= 0:
			stop_performing_action()
	else:
		stored_slow = min(max_stored_slow, stored_slow + slow_regen * delta)


func start_performing_action():
	super()
	Engine.time_scale = 1 - slow
	#Engine.physics_ticks_per_second = roundi(60 * (1 - slow))

func stop_performing_action():
	super()
	Engine.time_scale = 1
	#Engine.physics_ticks_per_second = 60


## Called on equiping
func ready() -> void:
	type = TYPES.SLOW_MOTION
	super()
	stored_slow = max_stored_slow
