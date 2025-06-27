extends CharacterAction
class_name RocketBoost

@export var particle_emitter_scene: PackedScene
var particle_emitter: GPUParticles3D

@export_category("Fuel")
@export var max_fuel: float = 1000
var fuel: float
## fuel/s, only regenerates while off
@export var fuel_regen: float = 100
## fuel/s
@export var fuel_usage: float = 150
## Used immediately on starting
@export var fuel_to_start: float = 200


func action_process(_delta: float) -> void:
	if Input.is_action_just_pressed("Use Rocket Engine") and fuel > fuel_to_start:
		if performing:
			stop_performing_action()
		else:
			attempt_action()


func action_physics_process(delta: float) -> void:
	if performing:
		fuel = max(0, fuel - fuel_usage * delta)
		player.velocity += player.velocity.normalized() * delta * 20
		particle_emitter.emitting = true
	elif fuel < max_fuel:
		fuel = min(max_fuel, fuel + fuel_regen * delta)
	if fuel == 0:
		stop_performing_action()


func start_performing_action() -> void:
	super()
	fuel -= fuel_to_start


func stop_performing_action() -> void:
	super()
	particle_emitter.emitting = false


func ready():
	type = TYPES.ROCKET_ENGINE
	super()
	fuel = max_fuel

	particle_emitter = particle_emitter_scene.instantiate()
	add_ability_object(particle_emitter, player)
