extends Node2D


const player_character_preload: PackedScene = preload(PATHS.ENTITY_PLAYER_CHARACTER)


func _ready() -> void:
	var character: PlayerCharacter = player_character_preload.instantiate()
	World.get_user_player_branch().spawn_node(character)

	# TODO BUG THIS CODE RUNS BEFORE SERVER HAS A CHANCE TO SEND USER PLAYER BRANCH via MultiplayerSpawner...
	# TEST spawning manually ahead-of–time...
	# TEST delegating until branch is spawned...
	# TEST remaking player branch spawning to not use MultiplayerSpawner, instead spawn manually with peer list
