extends Resource
class_name CharacterAction


@export var blocks_actions: Array[CharacterAction]
var type: TYPES = TYPES.NULL


enum TYPES {
	NULL,
	GROUNDED_STOP,
	RUN,
	JUMP,
	AIR_CONTROL,
	FREEFALL,
	SLIDE,
	ROCKET_ENGINE,
	GRAPPLING_HOOK,
	BURST_CHARGES,
	BOUNCE
}

var player: Player
## Anwser to the question "Do we perform the action this frame?"
var performing: bool = false
var ability_objects: Array[Node]


# Look at me ma! I've created resources with node functions!
## Called every _process tick of the player
func action_process(_delta: float) -> void:
	pass


## Called every _physics_process tick of the player
func action_physics_process(_delta: float) -> void:
	pass


## Called on equiping
func ready() -> void:
	assert(type != TYPES.NULL, "Called ready on a CharacterAction with no type")


## Check if the action is not blocked and start performing it if true
## Ignore the attempt if the action is currently being performed.
func attempt_action() -> void:
	if performing:
		return
	if player.blocked_actions.has(self):
		return
	start_performing_action()


## Inform the action it is supposed to be active and block conflicting actions
## but only if the action is not currently performed
func start_performing_action() -> void:
	assert(performing == false, "Called start_performing_action on an already perfomed action")
	performing = true
	## Stop performing actions that just have been blocked
	for blocked_action in blocks_actions:
		blocked_action.stop_performing_action()
		player.blocked_actions.append(blocked_action)


## Inform the action it is no longer active and unlock conflicting actions,
## but only if the action is currently performed
func stop_performing_action() -> void:
	if performing:
		performing = false
		for blocked_action in blocks_actions:
			player.blocked_actions.erase(blocked_action)


func add_ability_object(object: Node, parent: Node) -> void:
	ability_objects.append(object)
	parent.add_child(object)


func remove_ability_object(object: Node) -> void:
	assert(ability_objects.has(object), "Attempted to remove ability object that is not on the abilities list")
	ability_objects.erase(object)
	object.queue_free()
