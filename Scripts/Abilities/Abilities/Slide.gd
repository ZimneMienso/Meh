class_name Slide
extends CharacterAction


## The minimum speed for sliding by manual input.
@export_range(0, 5, 0.1, "or_greater") var slide_speed_treshold_high: float = 8
## The minimum speed for sliding continuation.
@export_range(0, 5, 0.1, "or_greater") var slide_speed_treshold_low: float = 3
@export_range(0, 50, 0.1, "or_greater") var jump_impulse: float = 16
## Is input currently treated as a command to stop the slide instead of starting.
var toggling_off: bool = false


## Passed down from the player
func action_input(event: InputEvent) -> void:
	if event.is_action("Slide"):
		if performing and Input.is_action_just_pressed("Slide"):
		## Block sliding until input released ("toggling" slide off).
			toggling_off = true
		if toggling_off and Input.is_action_just_released("Slide"):
			toggling_off = false


func action_physics_process(_delta: float) -> void:
	## -Must be on floor or slope.
	if player.is_on_slope() or player.is_on_floor2() and \
	## -Either manual input pressed while the it is treated as starting the action,
	## while also passing the minimum speed to start sliding manually treshold
	(Input.is_action_pressed("Slide") and not toggling_off and \
	player.velocity.length() > slide_speed_treshold_high or \
	## -Or if the player continues an already active slide uninterrupted
	check_slide_continuation()):
		if Input.is_action_just_pressed("Jump"):
			slide_jump()
		attempt_action()
	else:
		stop_performing_action()



func ready() -> void:
	type = TYPES.SLIDE
	super()


## Check if the player is going to continue the current slide.
# Add cases as needed.
func check_slide_continuation() -> bool:
	return \
	## -Must be already performing to continue.
	performing and \
	## -Must be at speed higher than treshold.
	player.velocity.length() > slide_speed_treshold_low and \
	## -Must not be actively toggling the slide off.
	not toggling_off and \
	## -Continue if player input on z axis points in the same direction as velocity or is 0.
	(player.input_vector3.z == 0 or signf(player.velocity.z) == signf(player.input_vector3.z))


func slide_jump() -> void:
	var slope_normal: Vector3 = player.last_slide_collision.get_collision_normal()
	## Redirect velocity towards slope normal if input.z is in the same direction as normal.z.
	if player.input_vector3.z and signf(player.input_vector3.z) == signf(slope_normal.z):
		player.velocity = player.velocity.length() * slope_normal
	## Otherwise do a vertical jump.
	else:
		player.velocity.y += max(0, jump_impulse - player.velocity.y)
