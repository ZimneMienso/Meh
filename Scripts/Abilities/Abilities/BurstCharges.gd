class_name BurstCharges
extends CharacterAction

# TODO Implement velocity rollback after collision
# TODO Separate particle variant for wall bounce

@export var impulse: float
@export var max_charges: int
var charges: int
@export var charge_regen: float
var charge_regen_progress: float
@export var use_cooldown: float
var use_cooldown_progress: float
## The distance in the direction opposite to input, at which if there is a wall
## at the moment of usting the ability, will redirect instead of cancelling
## velocity 
@export var wall_detection_range: float
@export var particle_emitter_scene: PackedScene

@export var trigger: AbilitySettingKeybind


## Called every _process tick of the player
func action_input(event: InputEvent) -> void:
	if not event.is_action(trigger.action_name):
		return
	var intput_vector: Vector2 = player.input_vector
	
	if Input.is_action_just_pressed(trigger.action_name) and intput_vector and \
	charges and use_cooldown_progress == 0:
		attempt_action()


func start_performing_action():
	super()
	charges -= 1
	use_cooldown_progress = use_cooldown
	
	## Do the thing
	## First, get the direction and project a raycast in the opposite one
		## Get opposite direction
	var opposite_direction2: Vector2 = -player.input_vector
	var opposite_direction3: Vector3 = \
	Vector3(0, opposite_direction2.y, opposite_direction2.x)
		## Create a raycast query
	var space_state: PhysicsDirectSpaceState3D = \
	player.get_world_3d().direct_space_state
	var query: PhysicsRayQueryParameters3D = \
	PhysicsRayQueryParameters3D.create(
		player.global_position, player.global_position + \
		opposite_direction3 * wall_detection_range
		)
	query.collision_mask = 1
	var query_result: Dictionary = \
	space_state.intersect_ray(query)
	
	## If the raycast hits a wall, redirect,
	## otherwise remove velocity in that direction
		## Calculate the portion of velocity in that direction
	var direction_angle: float = opposite_direction2.angle_to(Vector2.RIGHT)

	var velocity2: Vector2 = Vector2(player.velocity.z, player.velocity.y)

	var zeroed_velocity: Vector2 = velocity2.rotated(direction_angle)

	var velocity_in_direction2: Vector2 = \
	Vector2(max(0, zeroed_velocity.x), 0).rotated(-direction_angle)

	var velocity_in_direction3: Vector3 = Vector3(
	0,
	velocity_in_direction2.y,
	velocity_in_direction2.x)
	
	## Cancel velocity in the opposite direction
	player.velocity -= velocity_in_direction3

	## If near a wall, add the cancelled velocity to the impulse direction
	if query_result:
		player.velocity += player.input_vector3 * velocity_in_direction3.length()

	## Apply the "constant" impulse
	var impulse_velocity: Vector3 = player.input_vector3 * impulse
	player.velocity += impulse_velocity

	## Create new emitter and schedule it's death
	var particle_emitter: GPUParticles3D = particle_emitter_scene.instantiate()
	add_ability_object(particle_emitter, player)
	await particle_emitter.ready
	var emitter_timer: SceneTreeTimer = \
	player.get_tree().create_timer(1.0, false, true)
	emitter_timer.timeout.connect(remove_ability_object.bind(particle_emitter))

	## Fire the particles
	particle_emitter.look_at(
		player.global_position + opposite_direction3, Vector3.RIGHT)
	
	particle_emitter.emitting = true
	stop_performing_action()


func action_physics_process(delta: float) -> void:
	if charges < max_charges:
		charge_regen_progress = maxf(0, charge_regen_progress - delta)
		if charge_regen_progress == 0:
			charges += 1
			charge_regen_progress = charge_regen

	if use_cooldown_progress > 0:
		use_cooldown_progress = maxf(0, use_cooldown_progress - delta)


## Called on equiping
func ready() -> void:
	type = TYPES.BURST_CHARGES
	super()
