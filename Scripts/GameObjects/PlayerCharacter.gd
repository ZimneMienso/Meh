extends CharacterBody3D
class_name Player

@onready var anim_player: AnimationPlayer = $CharacterPlaceholder/AnimationPlayer

## Equipment slots present on the character itself
@export var eqslots: Array[EqSlot]
## Modifiers present on character at all times
@export var initial_attribute_modifiers: Array[AttributeModifier]
@export var inherent_abilities: Array[CharacterAction]

## A dictionary of references to the player node tree. Used by equipment and
## abilities to add their relevant meshes, particle emitters etc.
@export var bone_attachments: Dictionary[String, BoneAttachment3D]
@export var skeleton: Skeleton3D


enum CHAR_ACTIONS {
	GROUNDED_STOP,
	RUN,
	JUMP,
	AIR_CONTROL,
	FREEFALL,
	SLIDE,
	ROCKET_ENGINE,
	GRAPPLING_HOOK
}

var attributes: Array[Attribute]

var abilities: Array[CharacterAction]
var active_abilities: Array[CharacterAction]
var blocked_actions: Array[CharacterAction]


## A dictionary that holds arrays of nodes created from equipment data on equip/
## Used to free them on unequip
var equipment_nodes: Dictionary[Equipment, Array]

const anim_name_idle: String = "Armature|Idle"
const anim_name_run: String = "Armature|Run"


func _ready() -> void:
	CAMERAMAN.tracking = self

	## Create an attribute for each possible type of attribute
	## They are accessed by their index using TYPE enum in Attribute class
	for i in Attribute.TYPE.size():
		attributes.append(Attribute.new())

	initialize_equipment()

	INV.add_equipment(preload("res://Resources/Equipment/LightExoskeleton.tres"))


func _physics_process(delta: float) -> void:

	velocity += delta * get_gravity()
	move_and_slide()
	align_rotation_with_velocity()

	debug_update_stats_label()

	active_abilities.clear()
	for ability in abilities:
		ability.action_physics_process(delta)
		if ability.performing:
			active_abilities.append(ability)


func _process(delta: float) -> void:
	for ability in abilities:
		ability.action_process(delta)


func align_rotation_with_velocity():
	rotation.y = deg_to_rad(-sign(velocity.z) * 90 + 90)


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
	for attribute in attributes:
		attribute.attribute_modifiers.clear()
		attribute.calculate_value()
	
	## Apply initial modifiers
	for attribute_modifier in initial_attribute_modifiers:
		apply_attribute_modifier(attribute_modifier)


	## Reset abilities
	# Might be useful to be able to tell abilities when they are being freed
	#for ability in abilities:
		#ability.queue_free()
	abilities.clear()
	
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
		abilities.erase(ability)


## Apply the given modifier to the relevant attribute
func apply_attribute_modifier(modifier: AttributeModifier):
	attributes[modifier.attribute_type].add_modifier(modifier)


## Registers and enables the given ability for the player
func enable_ability(ability: CharacterAction):
	ability.player = self
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



# DEPRECATED grappling hook stuff
#func use_grappling_hook():
	#if not hook_attachments.is_empty():
		#hook_attachments.clear()
	#
	## Cursor projector on world 3000
	#var viewport: Viewport = get_viewport()
	#var camera: Camera3D = viewport.get_camera_3d()
	#var mouse_pos: Vector2 = viewport.get_mouse_position()
	#var projection_origin: Vector3 = camera.project_ray_origin(mouse_pos)
	#var projection_direction: Vector3 = camera.project_ray_normal(mouse_pos)
	#var projection_distance: float = -projection_origin.x / projection_direction.x
	#var mouse_projection: Vector3 = projection_origin + projection_direction * projection_distance
	#
	#var hook_lifetime: float = grappling_hook_range / grappling_hook_speed
#
	#var hook_placeholder: RigidBody3D = RigidBody3D.new()
	#hook_placeholder.gravity_scale = 0
	#hook_placeholder.collision_layer = 0
	#hook_placeholder.contact_monitor = true
	#hook_placeholder.max_contacts_reported = 1
	#var hook_placeholder_mesh_instance: MeshInstance3D = MeshInstance3D.new()
	#var hook_placeholder_mesh: SphereMesh = SphereMesh.new()
	#hook_placeholder_mesh.height = 0.25
	#hook_placeholder_mesh.radius = 0.125
	#var hook_placeholder_mesh_material: StandardMaterial3D = StandardMaterial3D.new()
	#hook_placeholder_mesh_material.albedo_color = Color(1,0,0)
	#hook_placeholder_mesh_instance.mesh = hook_placeholder_mesh
	#var hook_paceholder_collision_shape: CollisionShape3D = CollisionShape3D.new()
	#var hook_placeholder_collision_shape_shape: SphereShape3D = SphereShape3D.new()
	#hook_placeholder_collision_shape_shape.radius = 0.125
	#hook_paceholder_collision_shape.shape = hook_placeholder_collision_shape_shape
	#
	#
	#hook_placeholder.body_entered.connect(on_hook_projectile_collision.bind(hook_placeholder))
	#hook_placeholder.body_entered.connect(hook_placeholder.queue_free.unbind(1))
	#
	#get_parent().add_child(hook_placeholder)
	#
	#var timer: Timer = Timer.new()
	#hook_placeholder.add_child(timer)
	#timer.timeout.connect(hook_placeholder.queue_free)
	#timer.start(hook_lifetime)
	#
	#hook_placeholder.global_position = global_position + Vector3.UP
	#hook_placeholder.add_child(hook_placeholder_mesh_instance)
	#hook_placeholder.add_child(hook_paceholder_collision_shape)
	#hook_placeholder.linear_velocity = (mouse_projection - Vector3.UP - global_position).normalized() * grappling_hook_speed
#
#
#
#var hook_attach_point_debug: MeshInstance3D
#
#class HookAttachment:
	#extends Node3D
	#var hook_distance: float
#
#var hook_attachments: Array[HookAttachment]
#
#
#func on_hook_projectile_collision(hit_collider: Node3D, hook_placeholder: RigidBody3D):
	#attach_grappling_hook(hit_collider, hook_placeholder.global_position)
#
#
#func attach_grappling_hook(attach_to: Node3D, hook_position: Vector3):
	#hook_attach_point_debug = MeshInstance3D.new()
	#hook_attach_point_debug.mesh = SphereMesh.new()
	#hook_attach_point_debug.mesh.radius = 0.2
	#hook_attach_point_debug.mesh.height = 0.4
	#
	#var new_hook_attachment: HookAttachment = HookAttachment.new()
	#hook_attachments.append(new_hook_attachment)
	#attach_to.add_child(new_hook_attachment)
	#new_hook_attachment.global_position = hook_position
	#new_hook_attachment.global_position.x = 0
	#new_hook_attachment.hook_distance = (global_position - hook_position).length()
	#
	#new_hook_attachment.add_child(hook_attach_point_debug)
#
#
#func apply_grappling_hook_swing():
	#
#
	#if hook_attachments.is_empty():
		#return
#
	#var last_attachment: HookAttachment = hook_attachments[-1]
#
	##if global_position.distance_to(last_attachment.global_position) <= last_attachment.hook_distance:
	##	return
	#
	#var nearest_point_on_circle: Vector3 = \
	#last_attachment.global_position.direction_to(global_position) * \
	#last_attachment.hook_distance + last_attachment.global_position
#
	#var tangent_left: Vector3 = (last_attachment.to_local(nearest_point_on_circle)).cross(Vector3.LEFT).normalized()
	#var tangent_right: Vector3 = (last_attachment.to_local(nearest_point_on_circle)).cross(Vector3.RIGHT).normalized()


static func apply_constant_friction(delta: float, value: float, friction: float) -> float:
	return move_toward(value, 0, friction * delta)


func debug_update_stats_label():
	var text: String = \
	"
	Velocity = %s
	Actions = %s
	"

	
	var player_actions_text: Array[String]
	for ability in active_abilities:
		player_actions_text.append(CharacterAction.TYPES.find_key(ability.type))
	
	$StatsLabel.text = text % [velocity.round(), player_actions_text, ]
