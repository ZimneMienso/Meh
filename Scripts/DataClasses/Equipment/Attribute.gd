extends Resource
class_name Attribute


enum TYPE {
	NULL = -1,
	RUN_MAX_SPEED = 1,
	RUN_ACCELERATION = 2,
	GROUND_STOP_FRICTION = 3,
	FORCED_GROUND_STOP_ACCELERATION_BONUS = 4,
	JUMP_IMPULSE = 30,
	MAX_JUMP_VELOCITY = 31,
	AIR_ACCELERATION = 50,
	AIR_CONTROL_MAX_VELOCITY = 51,
	AIR_FRICTION = 52,
	CONSTANT_SLIDE_FRICTION = 70,
	FORCE_SLIDE_SLOPE_ANGLE = 71,
	GRAPPLING_HOOK_RANGE = 90,
	GRAPPLING_HOOK_SPEED = 91
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
