class_name SlowMotion
extends CharacterAction


@export var trigger: AbilitySettingKeybind
@export var relative_slowdown: AbilitySettingBool
## The percievable speed to which the time will slow down in relative mode.
@export var relative_slowdown_speed: float = 50

## Used as at a rate of 1/"normal" speed (Engine.time_scale == 1) second to 
## sustain the ability
@export var max_stored_slow: float
var stored_slow: float
## How much stored slow regenerates per second while the ability is off
@export var slow_regen: float
## By how much the game slows during the ability
@export_range(0, 0.9, 0.01) var slow: float
## Multiplies stored slow usage by this.
var cost_multiplier: float = 1
## How many outside things want this ability active.
var activator_count: int = 0
## All active discounts
var discounts: Array[float] = [1]
var native_activation: bool = false

func action_input(event: InputEvent) -> void:
	if not event.is_action(trigger.action_name):
		return
	if Input.is_action_just_pressed(trigger.action_name):
		if performing:
			stop_performing_action()
			native_activation = false
		elif stored_slow > 0.1:
			attempt_action()
			native_activation = true


## Called every _physics_process tick of the player
func action_physics_process(delta: float) -> void:
	if performing:
		if relative_slowdown.value == true:
			var time_scale: float = \
			min(relative_slowdown_speed / player.velocity.length(), 1 - slow)
			Engine.time_scale = time_scale
		stored_slow -= delta * cost_multiplier
		if stored_slow <= 0:
			stop_performing_action()
	else:
		stored_slow = min(max_stored_slow, stored_slow + slow_regen * delta)


func start_performing_action():
	super()
	Engine.time_scale = 1 - slow


func stop_performing_action():
	super()
	Engine.time_scale = 1
	cost_multiplier = 1


## Called on equiping
func ready() -> void:
	type = TYPES.SLOW_MOTION
	super()
	stored_slow = max_stored_slow


## Called when player sends an ability request.
## Expected parameters: [set_active: bool, cost_multiplier: float]
func anwser_request(parameters: Array) -> void:
	var set_active: bool = parameters[0]
	var multiplier: float = parameters[1]
	## Check if the request is to turn on or off.
	## Note: This assumes everything that requests slowmode will also
	## deactivate it exactly once per "cycle" so that activator count 
	## eventually returns to 0.
	if not set_active:
		activator_count = max(0, activator_count - 1)
		discounts.erase(multiplier)
		## If nothing requests it anymore, deactivate.
		if not native_activation and activator_count == 0:
			stop_performing_action()
	else:
		activator_count += 1
		discounts.append(multiplier)
		attempt_action()
	discounts.sort()
	cost_multiplier = discounts[0]
