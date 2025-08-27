## Abstraction of the mech at the strategic level. [br]
## This one is non-player.
class_name NPMech
extends Mech

@export var damage: float = 5

func attack(damage_value: float = 0) -> void:
	var damageable_targets: Array[MechRegion]
	damageable_targets.assign(
		MECH_SPACE.player_mech.targetable_regions.filter(
			MechRegion.can_be_damaged))
	if not damageable_targets:
		printerr("No more damageable targets.")
		return
	var target_region: MechRegion = damageable_targets.pick_random()
	target_region.receive_damage(damage)
