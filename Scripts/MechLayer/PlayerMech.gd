## Abstraction of the mech at the strategic level. [br]
## This one has an interior that can have holes the player can repair manually.
class_name PlayerMech
extends Mech

@export_group("Audio", "audio_")
@export var audio_death_explosion: AudioStream


var audio_player: AudioStreamPlayer

func _ready() -> void:
	assert(MECH_SPACE.player_mech == null, "Attempted to instantiate a second PlayerMech")
	MECH_SPACE.player_mech = self
	died.connect(MECH_SPACE._on_player_death)

	## Setup Audio
	var audio_players: Array[Node] = find_children("*", "AudioStreamPlayer", false)
	assert(audio_players.size() > 0, "No AudioStreamPlayer child found in player mech.")
	assert(audio_players.size() <= 1, "More than one AudioStreamPlayer found in player mech.")
	audio_player = audio_players[0]


func die() -> void:
	super()
	audio_player.stream = audio_death_explosion
	audio_player.play()
	$MechInterior/External/UI/GameOverPopup.show()
