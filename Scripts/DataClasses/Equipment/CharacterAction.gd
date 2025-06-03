extends Resource
class_name CharacterAction


@export var type: TYPES
@export var blocks_actions: Array[TYPES]

enum TYPES {
	GROUNDED_STOP,
	RUN,
	JUMP,
	AIR_CONTROL,
	FREEFALL,
	SLIDE,
	ROCKET_ENGINE,
	GRAPPLING_HOOK
}

var player: Player
## Anwser to the question "Do we perform the action this frame?"
var performing: bool = false
var ability_objects: Array[Node]


# Look at me ma! I've created resources with node functions!
## Called every _process tick of the player
func action_process(delta: float) -> void:
	pass


## Called every _physics_process tick of the player
func action_physics_process(delta: float) -> void:
	pass


func ready() -> void:
	pass


## Check if the action is not blocked and start performing it if true
## Ignore the attempt if the action is currently being attempted
func attempt_action() -> void:
	if performing:
		return
	if not player.blocked_actions.has(type):
		start_performing_action()


## Inform the action it is supposed to be active and block conflicting actions
func start_performing_action() -> void:
	performing = true
	player.blocked_actions.append_array(blocks_actions)


## Inform the action it is no longer active and unlock conflicting actions
func stop_performing_action() -> void:
	performing = false
	for action_type in blocks_actions:
		player.blocked_actions.erase(action_type)


func add_ability_object(object: Node, parent: Node) -> void:
	ability_objects.append(object)
	parent.add_child(object)


func remove_ability_object(object: Node) -> void:
	if not ability_objects.has(object):
		printerr("Attempted to remove ability object that is not on the abilities list")
		return
	ability_objects.erase(object)
	object.queue_free()
