extends Resource
## An abstract class that defines something the player character can do.
class_name CharacterAction


@export var blocks_actions: Array[CharacterAction]
var type: TYPES = TYPES.NULL

#@export var create_input_action: bool = false
## Also the name of the action that triggers it if create_input_action is true
var ability_name: String

@export var icon: Texture2D = preload("res://Assets/Icons/Placeholder Icon.png")
## Repair mode abilities only work when repair mode is active,
## receive inputs first and consume them.
@export var repair_mode: bool = false
## Is the ability displayed on the ability list in loadout menu etc.
## Needs to be true for the player to be able to configure the ability.
@export var show_in_menus: bool = true

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
	BOUNCE,
	SLOW_MOTION,
	REPAIR_MODE,
	FIXFOAM_CANNON,
	WALL_MOVEMENT
}

var player: Player
## Anwser to the question "Do we perform the action this frame?"
var performing: bool = false
var ability_objects: Array[Node]
var player_settings: Array[AbilitySetting]


# Look at me ma! I've created resources with node functions!

## Called every _process tick of the player
## Should be overriden with logic for handling input.
func action_process(_delta: float) -> void:
	pass


## Called every _physics_process tick of the player
func action_physics_process(_delta: float) -> void:
	pass


## Passed down from the player
func action_input(_event: InputEvent) -> void:
	pass


## Called when player sends an ability request.
func anwser_request(_parameters: Array) -> void:
	pass


## Called on equiping
## Should be overriden to define the type variable
func ready() -> void:
	assert(type != TYPES.NULL, "Called ready on a CharacterAction with no type")

	ability_name = TYPES.find_key(type)

	player_settings = get_player_settings()
	for setting in player_settings:
		if setting is AbilitySettingKeybind:
			setting.action_name = ability_name + "_" + setting.setting_text
			if not InputMap.has_action(setting.action_name):
				InputMap.add_action(setting.action_name)


## Check if the action is not blocked and start performing it if true
## Ignore the attempt if the action is currently being performed.
func attempt_action() -> void:
	if performing:
		return
	if not can_perform_action():
		return
	start_performing_action()


func can_perform_action() -> bool:
	if player.blocked_actions.has(type):
		return false
	return true


## Inform the action it is supposed to be active and block conflicting actions
func start_performing_action() -> void:
	assert(performing == false, "Called start_performing_action on an already perfomed action")
	performing = true
	## Stop performing actions that just have been blocked
	for blocked_action in blocks_actions:
		blocked_action.stop_performing_action()
		player.blocked_actions.append(blocked_action.type)


## Inform the action it is no longer active and unlock conflicting actions,
## but only if the action is currently performed
func stop_performing_action() -> void:
	if performing:
		performing = false
		for blocked_action in blocks_actions:
			player.blocked_actions.erase(blocked_action.type)


## Basically add_child() but registers the child as belonging to this ability
func add_ability_object(object: Node, parent: Node = player) -> void:
	ability_objects.append(object)
	parent.add_child.call_deferred(object)


## Basically queue_free() but unregisters the child from this ability
func remove_ability_object(object: Node) -> void:
	assert(ability_objects.has(object), "Attempted to remove ability object that is not on the abilities list")
	ability_objects.erase(object)
	object.queue_free()


## Returns all properties of AbilitySetting* type.
func get_player_settings() -> Array[AbilitySetting]:
	var result: Array[AbilitySetting]
	for property in get_property_list():
		var property_class_name: String = property["class_name"]
		if property_class_name.begins_with("AbilitySetting"):
			result.append(get(property["name"]))
	return result


## An ability on priority input list will have it's process_priority_input
## func called before any ability recieves normal input processing.
func register_in_priority_input() -> void:
	player.priority_input_abilities.append(self)


## Override it and call super(event) at the end if event was the one expected.
func process_priority_input(_event: InputEvent) -> void:
	player.priority_input_abilities.erase(self)
	player.get_viewport().set_input_as_handled()
