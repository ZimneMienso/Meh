class_name CharProj
extends Resource


class Cast_Endpoint:
	var position: Vector3
	var collider


enum COLLISION_MODE {
	## The projectile will move physically and detect collision using an RIGIDBODY.
	## Prone to all the shortcommings of the RIGIDBODY, notably fast, small shapes.
	RIGIDBODY,
	## Projects a ray towards the target and then fakes the movement.
	## Reliable and efficient but may produce unintuitive behavior if the projectile is
	## slow and the target is mobile, or if obstructions are likely to appear between
	## the point of firing and the target in flight. [br] [br]
	##
	## [b] Requires a rigid body "template" to be provided for duplication. [b]
	RAYCAST,
	## Sweeps an area for collisions. Similar to RAYCAST but accomodates
	## larger projectiles at the cost of complexity and efficiency.
	SHAPECAST
}


@export_group("Physics")
@export var collision_mode: COLLISION_MODE = COLLISION_MODE.RAYCAST
## Shape used for RIGIDBODY and SHAPECAST collision modes. Irrelevant otherwise.
@export var collision_shape: Shape3D
## Affects the magnitude of the velocity for RIGIDBODY and the delay between
## fire/hit, along with visuals otherwise.
@export var speed: float = 3
## For RAYCAST it's the scan range. [br]
## For RIGIDBODY it's the projectile lifespan after division by speed. [br]
## (TODO IDK what is it for SHAPECAST yet.)
@export var range: float = 10


#@export_subgroup("Flags", "collision")

## The layers the projectile scans for collisions. Irrelevant for RIGIDBODY
## as the "template" configuration will be used.
@export_flags_3d_physics var collision_mask = 1

@export_group("Visuals")
## Mesh that will be attached to the visible projectile.
@export var mesh: Mesh = SphereMesh.new()
## Scene that will be attached to the visible projectile.
@export var visuals_scene: PackedScene


var rigidbody: RigidBody3D
var projectile: Node3D


func initialize_projectile() -> void:
	if projectile:
		projectile.queue_free()
	projectile = Node3D.new()
	## Visuals
	if mesh:
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.mesh = mesh
		projectile.add_child(mesh_instance)
	if visuals_scene:
		var scene := visuals_scene.instantiate()
		projectile.add_child(scene)

	## Physics
	match collision_mode:
		COLLISION_MODE.RIGIDBODY:
			pass
		COLLISION_MODE.RAYCAST:
			pass
		COLLISION_MODE.SHAPECAST:
			pass


func create_projectile(parent: Node, direction: Vector3) -> Node3D:
	var new_proj: Node3D = projectile.duplicate()
	parent.add_child(new_proj)
	return new_proj


## 
func get_raycast_endpoint():
	pass
