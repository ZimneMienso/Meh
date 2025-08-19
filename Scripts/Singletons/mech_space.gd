## The abstraction of the interactions at the strategic level. [br]
## Handles mech to vehicle combat, mech state etc.
extends Node


var player_mech: PlayerMech
var enemy: Mech


func _on_player_death():
	#enemy.set_process(false)aa
	#enemy.set_physics_process(false)
	enemy.process_mode = Node.PROCESS_MODE_DISABLED


func _on_enemy_death():
	pass
