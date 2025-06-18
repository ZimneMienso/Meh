extends CharacterAction
class_name RocketBoost

@export var particle_emitter_scene: PackedScene
var particle_emitter: GPUParticles3D


func ready():
	type = TYPES.ROCKET_ENGINE
	super()

	particle_emitter = particle_emitter_scene.instantiate()
	player.add_child(particle_emitter)


func action_physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("Use Rocket Engine"):
		if performing:
			stop_performing_action()
		else:
			attempt_action()

	if performing:
		player.velocity += player.velocity.normalized() * delta * 20
		particle_emitter.emitting = true
