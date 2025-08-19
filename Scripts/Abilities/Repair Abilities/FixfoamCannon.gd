class_name FixfoamCannon
extends CharacterAction


@export var projectile: ProjectileEmitter
## The time between shots
@export var firing_period: float = 0.5
## How much does it repair per shot
@export var repair_value: float = 0.5
var firing_cooldown: float = 0


## Input events passed from the player
func action_input(event: InputEvent) -> void:
	if not event.is_action(ability_name):
		return
	if Input.is_action_pressed(ability_name) and firing_cooldown == 0:
			attempt_action()

	player.get_viewport().set_input_as_handled()


## Called every _process tick of the player
func action_process(_delta: float) -> void:
	pass


## Called every _physics_process tick of the player
func action_physics_process(delta: float) -> void:
	if performing:
		var target_pos: Vector3 = HF.project_cursor_on_world(player.get_viewport())
		projectile.fire(player.get_parent(), player.global_position + Vector3.UP * 1, target_pos)
		firing_cooldown = firing_period
		stop_performing_action()

	if firing_cooldown > 0:
		firing_cooldown = max(firing_cooldown - delta, 0)


## Called on equiping
func ready() -> void:
	type = TYPES.FIXFOAM_CANNON
	super()
	projectile.projectile_hit.connect(_on_projectile_hit)


func _on_projectile_hit(hit_data: ProjectileEmitter.ProjHitData):
	assert(hit_data.collider is MechStruct, "Received hit_data doesn't contain a MechStruct")
	var struct: MechStruct = hit_data.collider as MechStruct
	struct.receive_repair(repair_value)
