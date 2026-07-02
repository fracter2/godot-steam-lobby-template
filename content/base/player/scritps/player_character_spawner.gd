extends Node2D


const player_character_preload: PackedScene = preload(PATHS.ENTITY_PLAYER_CHARACTER)


func _ready() -> void:
	_spawn_player.call_deferred()	# NOTE deffered since everything is  still loading

func _spawn_player() -> void:
	var character: PlayerCharacter = player_character_preload.instantiate()
	World.get_user_player_branch().spawn_node(character)
