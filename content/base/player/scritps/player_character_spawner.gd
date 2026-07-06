extends Node2D


const player_character_preload: PackedScene = preload(PATHS.ENTITY_PLAYER_CHARACTER)

@export_range(0, 100, 1, "or_greater") var spawn_radius: int = 60
@export_range(1, 16, 1, "or_greater") var spawns_before_loop: int = 8
var spawn_count: int = 0


func _ready() -> void:
	if multiplayer.is_server():
		#Lobby.player_added.connect()
		multiplayer.peer_connected.connect(_on_peer_connected, CONNECT_DEFERRED)
		_spawn_player.call_deferred(1)	# NOTE deffered since everything is  still loading


func _get_spawn_offset() -> Vector2:
	if spawn_radius == 0 or spawns_before_loop == 1:
		return Vector2.ZERO
	else:
		return Vector2(spawn_radius, 0).rotated((spawn_count * 2 * PI) / spawns_before_loop)


func _on_peer_connected(id: int) -> void:
	spawn_count += 1
	_spawn_player.rpc_id(id, spawn_count)



@rpc("authority")
func _spawn_player(new_spawn_count: int) -> void:
	spawn_count = new_spawn_count
	var character: PlayerCharacter = player_character_preload.instantiate()
	character.position = global_position + _get_spawn_offset()
	ClientSpawnManager.spawn(character)
