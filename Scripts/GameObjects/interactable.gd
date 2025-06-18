extends Area3D

signal interaction

var player_in_range: bool = false

func _on_body_entered() -> void:
	player_in_range = true


func _on_body_exited() -> void:
	player_in_range = false


func _process(_delta: float) -> void:
	if not player_in_range:
		return
	if Input.is_action_just_pressed("Interact"):
		interaction.emit()
