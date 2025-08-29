## Defines a projectile and enables it to be fired. [br]
## When it collides, depending on the settings,
## it sends a projectile_hit signal with the hit collider and collision position. [br]
## When it dies it sends a projectile_died signal with death position.
class_name ProjectileEmitter
extends Resource


@warning_ignore("unused_signal")
signal projectile_hit(hit_data: ProjHitData)
@warning_ignore("unused_signal")
signal projectile_died(position: Vector3)


## Holds a reference to the collider and the point of collision from a single
## collision event
class ProjHitData:
	var collider: CollisionObject3D
	var collision_pos: Vector3


## How fast the projectile moves.
@export_range(0, 100, 1, "or_greater") var projectile_speed: float
## How far can the projectile fly before dying.
@export_range(0.001, 100, 1, "or_greater") var projectile_range: float
## How many targets can the projectile hit before dying. [br]
## 0 for infinite.
@export_range(0, 10, 1, "or_greater") var max_hits: int = 1

@export_group("Visuals")
## Optional mesh that will be attached to the visible projectile.
@export var mesh: Mesh
@export_range(0, 360, 1, "radians_as_degrees") var mesh_x_rotation: float = PI * 1.5
## Optional scene that will be attached to the visible projectile.
@export var visuals_scene: PackedScene
@export var rotate_to_velocity: bool = true

@export_group("Collisions")
## The physics layers projectiles will trigger when collided on.
@export_flags_3d_physics var target_collision_mask = 0
## The physics layer considered "terrain".
@export_flags_3d_physics var terrain_collision_mask = 0
@export var die_on_terrain: bool = true
## If true the projectile will report a hit when colliding with terrain
@export var trigger_on_terrain: bool = false
@export var reduce_hits_on_terrain: bool = true


## Creates the projectile in the world and returns the fired projectile.
func fire(_parent: Node3D, _origin: Vector3, _target: Vector3) -> Node3D:
	return null
