class_name CastProjectileEmitter
extends ProjectileEmitter


class FakeProjectile:
	extends  Node3D
	
	var velocity: Vector3


	func _init(new_velocity: Vector3, children: Array[Node]) -> void:
		velocity = new_velocity
		for child in children:
			add_child(child)


	func _physics_process(delta: float) -> void:
		global_position += velocity * delta


@export_group("Cast Projectile")
## Ignore projectile speed for physics (fake projectile will still use speed).
@export var instantaneous: bool = false
## Create a visual instance that will travel along the direction of travel
## up to the point of collision.
@export var create_fake_projectile: bool = true
@export var fire_on_miss: bool = true
## If false, the projectile will use distance to target as it's range if it's
## lower than it's max range.
@export var overshoot: bool = true


func fire_fake_proj(parent: Node, origin: Vector3, target: Vector3):
	## Visuals
	var fake_proj_visuals: Array[Node]
	if mesh:
		var new_mesh_instance := MeshInstance3D.new()
		new_mesh_instance.rotation.x = mesh_x_rotation
		new_mesh_instance.mesh = mesh
		fake_proj_visuals.append(new_mesh_instance)
	if visuals_scene:
		var visual_scene_instance := visuals_scene.instantiate()
		fake_proj_visuals.append(visual_scene_instance)
	## Setup the FakeProjectile object
	## Movement direction
	var fake_proj_direction: Vector3 = origin.direction_to(target)
	var fake_proj: FakeProjectile = FakeProjectile.new(
		fake_proj_direction * projectile_speed, fake_proj_visuals)
	parent.add_child(fake_proj)
	fake_proj.global_position = origin
	## Rotate to velocity
	if rotate_to_velocity:
		fake_proj.look_at(target)
	## Death
	var death_delay: float = origin.distance_to(target) / projectile_speed
	var death_timer := fake_proj.get_tree().create_timer(death_delay, false, true)
	death_timer.timeout.connect(fake_proj.queue_free)
