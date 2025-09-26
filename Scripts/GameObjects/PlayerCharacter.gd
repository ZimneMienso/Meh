extends CharacterBody3D
class_name Player

enum COLLISION_STATES {
	AIR,
	FLOOR,
	WALL,
	CEILING
}


@export var anim_player: AnimationPlayer
@export var visual_only_body: Node3D

## Equipment slots present on the character itself
@export var eqslots: Array[EqSlot]
## Modifiers present on character at all times
@export var initial_attribute_modifiers: Array[AttributeModifier]
@export var inherent_abilities: Array[CharacterAction]

## A dictionary of references to the player node tree. Used by equipment and
## abilities to add their relevant meshes, particle emitters etc.
@export var bone_attachments: Dictionary[String, BoneAttachment3D]
@export var skeleton: Skeleton3D

@export var temp_debug1: Node3D
@export var temp_debug2: Node3D

var attributes: Dictionary[int, Attribute]

var abilities: Array[CharacterAction]
var repair_mode_abilities: Array[CharacterAction]
var priority_input_abilities: Array[CharacterAction]
var active_abilities: Array[int]
var blocked_actions: Array[int]

## A dictionary that holds arrays of nodes created from equipment data on equip.
## Used to free them on unequip.
var equipment_nodes: Dictionary[Equipment, Array]

var input_vector: Vector2
var input_vector3: Vector3

@export_group("Coyote Time")
@export_range(0, 1, 0.01, "or_greater") var velocity_rollback_duration: float
var last_collision_rollback_event: CollisionRollbackEvent
## Abilities that are actively blocking rollback recording and reading.
var collision_rollback_blockers: Array[CharacterAction] = []
var previous_frame_collision: PhysicsTestMotionResult3D = null
var last_frame_velocity: Vector3

@export_group("Slide MK2")
## On collision at this or lower angle of attack, retain 100% of speed and
## redirect velocity along the surface. 
@export_range(0, 90, 1, "radians_as_degrees") var min_speed_retention_angle: float = deg_to_rad(45)
## On collision at this or greater angle of attack, cancel all velocity 
## towards the surface.
@export_range(0, 90, 1, "radians_as_degrees") var max_speed_retention_angle: float = deg_to_rad(75)
## The maximum angle at which a slope will still be considered a floor or a ceiling.
@export_range(0, 90, 1, "radians_as_degrees") var horizontal_surface_max_angle: float = deg_to_rad(45)
## The maximum count of "bounces" the sliding algorithm makes.
@export_range(1, 8, 1, "or_greater") var max_bounces: int = 6
@export_subgroup("Snapping", "snapping")
## The distance snapping will check for collisions
@export_range(0.01, 5, 0.01, "or_greater") var snapping_lenght: float = 0.2
## The the magnitude of the velocity in the direction of the attached surface
## normal that will cause detachment from that surface.
@export_range(0, 5, 0.1, "or_greater") var snapping_detach_speed: float = 0
## Speed below which snapping will not occur (fixes gravity-induced sliding on
## flat horizontal surfaces)
@export_range(1, 10, 0.1, "or_greater") var snapping_speed_treshold: float = 3
## The distance the body will be moved away from a surface as snapping is stopped.
@export_range(0, 2, 0.01, "or_greater") var snapping_detach_lenght: float = 0.2
## The direction that will be checked for surfaces for the purpose of snapping.
var snapping_direction: Vector3 = Vector3.ZERO
var last_slide_collision: PhysicsTestMotionResult3D = null

## The type of surface touched during the last move_and_slide_mk2().
var collision_state: COLLISION_STATES
## The maximum angle between the snapping direction and input vector before unsnapping.
const snapping_input_tolerance: float = deg_to_rad(105)

const anim_name_idle: String = "Armature|Idle"
const anim_name_run: String = "Armature|Run"

# TODO This is jank, move it somewhere less moronic when you do game saving or
# loadout handling
const ability_keybind_cfg_path: String = "user://AbilityKeybinds.cfg"


class CollisionRollbackEvent:
	var collision: PhysicsTestMotionResult3D
	var pre_collision_velocity: Vector3
	var time_left: float


	func _init(new_collision: PhysicsTestMotionResult3D, new_velocity: Vector3, duration: float) -> void:
		collision = new_collision
		pre_collision_velocity = new_velocity
		time_left = duration


	## Ticks the timer and returns false if the event is expired.
	func process(delta: float) -> bool:
		time_left -= delta
		return time_left > 0


func _ready() -> void:
	CAMERAMAN.tracking = self

	## Create an attribute for each possible type of attribute
	## They are accessed by their index using TYPE enum in Attribute class
	for attribute_type in Attribute.TYPE:
		if Attribute.TYPE[attribute_type] == Attribute.TYPE.NULL:
			continue
		attributes.set(Attribute.TYPE[attribute_type], Attribute.new())

	initialize_equipment()

	INV.add_equipment(preload("res://Resources/Equipment/LightExoskeleton.tres"))

	## Load ability keybinds
	if not FileAccess.file_exists(ability_keybind_cfg_path):
		return
	var ability_keybind_cfg: ConfigFile = ConfigFile.new()
	ability_keybind_cfg.load(ability_keybind_cfg_path)

	var section: String = ability_keybind_cfg.get_sections()[0]
	for ability_name in ability_keybind_cfg.get_section_keys(section):
		var key: InputEvent = \
		ability_keybind_cfg.get_value(section, ability_name)
		if not InputMap.has_action(ability_name):
			InputMap.add_action(ability_name)
		InputMap.action_add_event(ability_name, key)


func _physics_process(delta: float) -> void:

	debug_update_stats_label()

## Movement
	previous_frame_collision = last_slide_collision
	## Clear the collision so that the move and slide might write it again
	last_slide_collision = null
	var move_and_slide_vector: Vector3 = move_and_slide_mk2(velocity * delta)
	global_position += move_and_slide_vector
	apply_snap()
	velocity += delta * get_gravity()

	align_rotation_with_velocity()

## Corrections
	velocity.x = 0
	global_position.x = 0

## Coyote time
	if last_slide_collision:
		update_velocity_rollback()
	process_velocity_rollback(delta)

## Ability physics process
	active_abilities.clear()
	for ability in abilities:
		ability.action_physics_process(delta)
		if ability.performing:
			active_abilities.append(ability.type)
	for ability in repair_mode_abilities:
		ability.action_physics_process(delta)
		if ability.performing:
			active_abilities.append(ability.type)

## Air friction
	var air_friction: float = get_attribute(Attribute.TYPE.AIR_FRICTION)
	if not is_on_floor2() and velocity.length() > 2:
		velocity -= velocity.normalized() * air_friction * delta

	last_frame_velocity = velocity 


func _process(delta: float) -> void:

	input_vector = Input.get_vector("Move Right", "Move Left", "Move Down", "Move Up")
	input_vector3 = Vector3(0, input_vector.y, input_vector.x)

	for ability in abilities:
		ability.action_process(delta)
	for ability in repair_mode_abilities:
		ability.action_process(delta)


func _unhandled_input(event: InputEvent) -> void:
	## Ignore mouse motion
	if event is InputEventMouseMotion:
		return

	## Process priority input before anything else.
	for ability in priority_input_abilities:
		ability.process_priority_input(event)
		## At this point the ability should have consumed the input.
		if get_viewport().is_input_handled():
			return

	## Process repair mode abilities first if in repair mode or not at all otherwise
	if active_abilities.has(CharacterAction.TYPES.REPAIR_MODE):
		for ability in repair_mode_abilities:
			ability.action_input(event)
	## Don't process non repair mode abilities if any repair mode ability
	## consumed the input. Has to be manually checked because stopping input
	## propagation doesn't do anything if it's all handled from this method.
		if get_viewport().is_input_handled():
			return

	## Process non repair mode abilities
	for ability in abilities:
		ability.action_input(event)

#region Movement

func move_and_slide_mk2(travel: Vector3, from: Vector3 = transform.origin, depth: int = 1) -> Vector3:
	if depth > 5:
		return Vector3.ZERO

	## Test move
	var collision_param := PhysicsTestMotionParameters3D.new()
	collision_param.max_collisions = 4
	collision_param.from = transform
	collision_param.from.origin = from
	collision_param.motion = travel
	collision_param.margin = safe_margin
	collision_param.recovery_as_collision = true
	var collision := PhysicsTestMotionResult3D.new()

	if PhysicsServer3D.body_test_motion(get_rid(), collision_param, collision) and \
	## Treat collisions "along" the surface as if there was no collision.
	collision.get_collision_normal().dot(travel) != 0:
		var slide_vector: Vector3 = collision.get_remainder().slide(
			collision.get_collision_normal()).normalized() * collision.get_remainder().length()
		## Redirect velocity in the direction of the slide. If the direction is zero
		## (happens when the normal and travel are parallel), use travel direction instead.
		var velocity_redirect: Vector3 = slide_vector
		if slide_vector == Vector3.ZERO:
			velocity_redirect = collision.get_travel()
		## Calculate the fraction of the velocity that remains after the collision.
		var angle_of_attack: float = collision.get_collision_normal().angle_to(travel) - PI/2
		var speed_retention: float = clampf(remap(
		angle_of_attack,
		min_speed_retention_angle, 
		max_speed_retention_angle,
		1, 0), 0, 1)
		velocity = velocity_redirect.normalized() * velocity.length() * speed_retention
		last_slide_collision = collision
		return collision.get_travel() + move_and_slide_mk2(slide_vector, from + slide_vector, depth + 1)
	## No collision
	return travel


func apply_snap():
	if last_slide_collision:
		snapping_direction = -last_slide_collision.get_collision_normal()

## Snapping
	## Check if snapping is desired at all.
	# TODO Wall and ceiling snapping as an option
	# TODO Keep collision state consistent
	if snapping_direction != Vector3.ZERO:
		## Perform a test move in the reverse direction of collided surface normal
		## up to the maximum snapping_lenght
		var collision_param := PhysicsTestMotionParameters3D.new()
		collision_param.max_collisions = 4
		collision_param.from = transform
		collision_param.motion = snapping_direction * snapping_lenght
		collision_param.margin = safe_margin
		collision_param.recovery_as_collision = true
		collision_param.collide_separation_ray = true
		var collision := PhysicsTestMotionResult3D.new()

		## Decide to either snap to a surface or stop snapping. Snap if:
		## -If the test move hit anything. 
		if PhysicsServer3D.body_test_motion(get_rid(), collision_param, collision) and \
		## -The speed in the opposite direction is lower than
		## the snapping_detach_speed.
		HF.get_speed_in_direction(collision.get_collision_normal(), velocity) < \
		snapping_detach_speed:
			global_position += collision.get_travel()
			if not last_slide_collision:
				last_slide_collision = collision
			#snapping_direction = -collision.get_collision_normal()
			## Else, don't/stop snapping.
		else:
			snapping_direction = Vector3.ZERO

	## Collision state evaluation
		match snapping_direction:
			var direction when direction == Vector3.ZERO:
				collision_state = COLLISION_STATES.AIR
			var direction when direction.angle_to(Vector3.DOWN) < horizontal_surface_max_angle:
				collision_state = COLLISION_STATES.FLOOR
			var direction when direction.angle_to(Vector3.DOWN) > PI - horizontal_surface_max_angle:
				collision_state = COLLISION_STATES.CEILING
			_:
				collision_state = COLLISION_STATES.WALL
		#print(rad_to_deg(snapping_direction.angle_to(Vector3.DOWN)), " ", rad_to_deg(horizontal_surface_max_angle))


func is_in_air() -> bool:
	return collision_state == COLLISION_STATES.AIR


func is_on_floor2() -> bool:
	return collision_state == COLLISION_STATES.FLOOR


func is_on_wall2() -> bool:
	return collision_state == COLLISION_STATES.WALL


func is_on_ceiling2() -> bool:
	return collision_state == COLLISION_STATES.CEILING


## Returns the normal of the last slide collision surface.
## Returns Vector3.ZERO if there was no collision.
func get_contact_normal() -> Vector3:
	if last_slide_collision:
		return last_slide_collision.get_collision_normal()
	return Vector3.ZERO


## Returns the minimum angle between the last slide collision surface and Vector3.UP.
## The value is always positive, unless there was no collision last move and slide call,
## in this case it will return -1.
func get_contact_angle() -> float:
	if last_slide_collision:
		return get_contact_normal().angle_to(Vector3.UP)
	return -1

#endregion Movement


func align_rotation_with_velocity():
	visual_only_body.rotation.y = deg_to_rad(-sign(velocity.z) * 90 + 90)


#region Equipment and Attributes


func get_attribute(type: Attribute.TYPE) -> float:
	return attributes[type].value


func initialize_equipment():
	## Reset equipment nodes
	for equipment in equipment_nodes:
		for node in equipment_nodes[equipment]:
			node.queue_free()
	equipment_nodes.clear()


	## Reset attributes
	for attribute_index in attributes:
		var attribute: Attribute = attributes[attribute_index]
		attribute.attribute_modifiers.clear()
		attribute.calculate_value()
	
	## Apply initial modifiers
	for attribute_modifier in initial_attribute_modifiers:
		apply_attribute_modifier(attribute_modifier)


	## Reset abilities
	for ability in abilities:
		for ability_object in ability.ability_objects:
			ability.remove_ability_object(ability_object)
	for ability in repair_mode_abilities:
		for ability_object in ability.ability_objects:
			ability.remove_ability_object(ability_object)
	abilities.clear()
	repair_mode_abilities.clear()

	## Enable inherent abilities
	for ability in inherent_abilities:
		enable_ability(ability)


	## Get all equiped equipment
	var occupied_eq_slots: Array[EqSlot] = get_loadout_slots().filter(
		func(slot: EqSlot): if slot.current_equipment: return true else: return false
	)

	for slot in occupied_eq_slots:
		apply_equipment_properties(slot.current_equipment)


## Applies all the effects given equipment should have on the player
## Does not interact with EqSlots in any way, look for INV for that
func apply_equipment_properties(equipment: Equipment):
	## Equpment nodes
	## Get the scenes, instantiate, find attachment, if no attachment, create
	## one and append to bone_attachments, add child to the attachment
	for scene in equipment.equipment_nodes:
		var node: Node = scene.instantiate()
		var bone_name: String = equipment.equipment_nodes.get(scene)
		
		if not bone_attachments.has(bone_name):
			assert(skeleton.find_bone(bone_name) != -1)
			var new_attachment: BoneAttachment3D = BoneAttachment3D.new()
			new_attachment.name = bone_name
			new_attachment.bone_name = bone_name
			skeleton.add_child(new_attachment)
			bone_attachments.set(bone_name, new_attachment)

		bone_attachments[bone_name].add_child(node)
		equipment_nodes.set(equipment,[])
		equipment_nodes[equipment].append(node)

	## Attributes
	print("Equiped ", equipment.name)
	for attribute_modifier in equipment.attribute_modifiers:
		apply_attribute_modifier(attribute_modifier)
		
		print("Increased attribute ",
		Attribute.TYPE.find_key(attribute_modifier.attribute_type),
		" by ",
		attribute_modifier.value)

	## Abilities
	for ability in equipment.abilities:
		enable_ability(ability)


## Removes all the effects given equipment has on the player
## Does not interact with EqSlots in any way, look for INV for that
func remove_equipment_properties(equipment: Equipment):
	## Equpment nodes
	for node in equipment_nodes[equipment]:
		node.queue_free()
	equipment_nodes.erase(equipment)

	## Attributes
	for attribute_modifier in equipment.attribute_modifiers:
		attributes[attribute_modifier.attribute_type].remove_modifier(attribute_modifier)

	## Abilities
	for ability in equipment.abilities:
		if ability.repair_mode:
			repair_mode_abilities.erase(ability)
		else:
			abilities.erase(ability)


## Apply the given modifier to the relevant attribute
func apply_attribute_modifier(modifier: AttributeModifier):
	attributes[modifier.attribute_type].add_modifier(modifier)


## Registers and enables the given ability for the player
func enable_ability(ability: CharacterAction):
	ability.player = self
	if ability.repair_mode:
		repair_mode_abilities.append(ability)
	else:
		abilities.append(ability)
	ability.ready()


## Recursively finds all EqSlots on the character
func get_loadout_slots() -> Array[EqSlot]:
	var search: Array[EqSlot] = eqslots
	for slot in search:
		if slot.current_equipment and slot.current_equipment.eqslots:
			search.append_array(slot.current_equipment.eqslots)

	return search


## Recursively find all slots that match the given tag
func get_loadout_slots_matching_tag(tag: EqSlot.TAGS) -> Array[EqSlot]:
	var matching_slots: Array[EqSlot] = []
	var loadout_slots: Array[EqSlot] = get_loadout_slots()
	for slot in loadout_slots:
		## Check each slot for the searched tag
		if slot.tags.has(tag):
			matching_slots.append(slot)

	return matching_slots


## Returns all EqSlots that can fit the given equipment, regardless if the
## slots are full or not
func get_loadout_slots_matching_equipment(equipment: Equipment) -> Array[EqSlot]:
	var result: Array[EqSlot] = []
	for tag in equipment.tags:
		var matching_slots: Array[EqSlot] = get_loadout_slots_matching_tag(tag)
		for slot in matching_slots:
			if not result.has(slot):
				result.append(slot)

	return result


#endregion Equipment and Attributes


static func apply_constant_friction(delta: float, value: float, friction: float) -> float:
	return move_toward(value, 0, friction * delta)


## Finds the specified ability and makes it anwser to the parameters.
func send_ability_request(ability_type: CharacterAction.TYPES, parameters: Array) -> void:
	for ability in abilities:
		if ability.type == ability_type:
			ability.anwser_request(parameters)
			return
	for ability in repair_mode_abilities:
		if ability.type == ability_type:
			ability.anwser_request(parameters)
			return
	printerr("send_ability_request() could not find the ability " + CharacterAction.TYPES.find_key(ability_type))


## Records a new velocity rollback event if it's velocity is higher than the
## current one's.
func update_velocity_rollback() -> void:
	if collision_rollback_blockers:
		return
	if last_collision_rollback_event and last_frame_velocity.length() < \
	last_collision_rollback_event.pre_collision_velocity.length():
		return
	last_collision_rollback_event = CollisionRollbackEvent.new(
		last_slide_collision,
		last_frame_velocity,
		velocity_rollback_duration
	)


## Applies time to everything collision rollback related.
func process_velocity_rollback(delta: float) -> void:
	if not last_collision_rollback_event:
		return
	if not last_collision_rollback_event.process(delta):
		last_collision_rollback_event = null


## Returns the recorded collision rollback event and consumes it.
func get_velocity_rollback() -> CollisionRollbackEvent:
	if collision_rollback_blockers:
		return null
	var result := last_collision_rollback_event
	last_collision_rollback_event = null
	return result


func debug_update_stats_label():
	var text: String = \
	"
	Velocity = %s
	Actions = %s
	Collision State = %s
	"

	
	var player_actions_text: Array[String]
	for ability in active_abilities:
		player_actions_text.append(CharacterAction.TYPES.find_key(ability))
	
	$StatsLabel.text = text % [velocity.round(), player_actions_text, COLLISION_STATES.find_key(collision_state)]
