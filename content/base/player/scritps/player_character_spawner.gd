extends Node2D


const player_character_preload: PackedScene = preload(PATHS.ENTITY_PLAYER_CHARACTER)


func _ready() -> void:
	var character: PlayerCharacter = player_character_preload.instantiate()
	World.get_user_player_branch().spawn_node(character)
