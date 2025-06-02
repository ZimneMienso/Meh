extends Node

const camera_assembly_scene_path: String = "res://Scenes/GameObjects/Cameraman.tscn"

var cameraman: Node3D
var camera: Camera3D

var tracking: Node3D

func _ready() -> void:
	cameraman = preload(camera_assembly_scene_path).instantiate()
	add_child(cameraman)
	camera = cameraman.get_node("Camera3D")


func _process(delta: float) -> void:
	if tracking:
		cameraman.global_position = tracking.global_position


func default_mode() -> void:
	camera.position = Vector3(7.776, 0.108, 0)
	camera.rotation = Vector3(deg_to_rad(-6.8), deg_to_rad(90), deg_to_rad(0))


func loadout_mode() -> void:
	camera.position = Vector3(1.672, 0.98, 0)
	camera.rotation = Vector3(deg_to_rad(-6.8), deg_to_rad(90), deg_to_rad(0))
