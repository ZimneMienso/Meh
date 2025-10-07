class_name TargetMarker
extends Node3D

const distance_to_parent: float = 1
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var mesh: MeshInstance3D = $TargetMarker
var rps: float = 0.25

func _ready() -> void:
	assert(get_parent_node_3d(), "TargetMarker is not a child of Node3D and will not work properly.")


func _process(_delta: float) -> void:
	mesh.rotation.z = wrapf(rps * 2 * PI * Time.get_ticks_msec() / 1000, 0, 2*PI)
	var camera_pos: Vector3 = get_viewport().get_camera_3d().global_position
	var look_vector: Vector3 = (camera_pos - get_parent().global_position).normalized()
	look_at_from_position(
		look_vector * distance_to_parent + get_parent().global_position,
		camera_pos)


func lock_on(revolutions_per_second: float = 0.25) -> void:
	rps = revolutions_per_second
	anim_player.play("TargetMarkerLock")


func lock_off() -> void:
	anim_player.play("TargetMarkerLock", -1, -3.2, true)
	await anim_player.animation_finished
	queue_free()
