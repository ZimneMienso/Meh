extends Resource
class_name Attribute


enum TYPE {
	RUN_MAX_SPEED,
	RUN_ACCELERATION,
	GROUND_STOP_FRICTION,
	JUMP_IMPULSE,
	MAX_JUMP_VELOCITY,
	AIR_ACCELERATION,
	AIR_CONTROL_MAX_VELOCITY,
	AIR_FRICTION,
	CONSTANT_SLIDE_FRICTION,
	FORCE_SLIDE_SLOPE_ANGLE,
	GRAPPLING_HOOK_RANGE,
	GRAPPLING_HOOK_SPEED
}

var value: float = 0
var attribute_modifiers: Array[AttributeModifier]


func calculate_value():
	var add: float = 0
	var multiply: float = 0


	for attribute_modifier in attribute_modifiers:
		match attribute_modifier.bonus_type:
			attribute_modifier.TYPE.ADD:
				add += attribute_modifier.value
			attribute_modifier.TYPE.MULTIPLIER:
				multiply += attribute_modifier.value

	value = (add * (1 + multiply))


func add_modifier(modifier: AttributeModifier):
	attribute_modifiers.append(modifier)
	calculate_value()


func remove_modifier(modifier: AttributeModifier):
	attribute_modifiers.erase(modifier)
	calculate_value()
