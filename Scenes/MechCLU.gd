## Central Logic Unit. The brain of the mech. Provides processing power.
## Total destruction means loss.
extends MechSystem


func receive_damage(value: float) -> void:
	super(value)
	if durability <= 0:
		mech_parent.die()
		pass
