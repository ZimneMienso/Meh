extends Node

const camera_assembly_scene_path: String = "res://Cameraman.tscn"

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
