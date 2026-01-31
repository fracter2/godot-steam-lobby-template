extends Node2D

@onready var multiplayer_spawner: MultiplayerSpawner = $MultiplayerSpawner
@onready var networked_entities: Node2D = $NetworkedEntities

const PREL_PLAYER = preload("uid://ctac7w7mgcdq8")

var player_nodes: Dictionary[int, Player] = {}


func _ready() -> void:
	Lobby.connected.connect(_on_connected)										# NOTE Local connected only
	Lobby.disconnected.connect(_on_disconnected)

	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	multiplayer_spawner.spawned.connect(_check_if_player_spawned)
	multiplayer_spawner.despawned.connect(_check_if_player_despawned)


func _on_connected() -> void:
	multiplayer.multiplayer_peer = Lobby.multiplayer.multiplayer_peer

func _on_disconnected(message: String) -> void:
	# TODO Quit level? set multiplayer peer again?
	pass


func _on_peer_connected(peer_id: int) -> void:
	if multiplayer.is_server():
		_spawn_player(peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
	if multiplayer.is_server():
		assert(player_nodes.has(peer_id))
		player_nodes[peer_id].queue_free()
		player_nodes.erase(peer_id)												# NOTE player_nodes is kept synced on remote peers by the MultiplayerSpawner signal callbacks


func _spawn_player(id: int) -> void:
	assert(multiplayer.is_server())
	assert(not player_nodes.has(id), "in _spawn_player() Spawning a player that is already registered!")

	var player_instance: Player = PREL_PLAYER.instantiate()
	player_instance.peer_id = id
	player_nodes[id] = player_instance											# NOTE player_nodes is kept synced on remote peers by the MultiplayerSpawner signal callbacks
	networked_entities.add_child(player_instance)

#func _despawn_player(id: int) -> void:

## Adds the node to [member player_nodes] if it is a [Player]
func _check_if_player_spawned(node: Node) -> void:
	assert(not multiplayer.is_server(), "_on_entity_spawned() should only be called by non-servers, as described in the MultiplayerSpawner signal description.")
	if node is Player:
		assert(not player_nodes.has(node.peer_id), "in _on_entity_spawned(), a new player node shouldn't already be registered here. obviously.")
		player_nodes[node.peer_id] = node

## Removes the node from [member player_nodes] if it is a [Player]
func _check_if_player_despawned(node: Node) -> void:
	assert(not multiplayer.is_server(), "_on_entity_despawned() should only be called by non-servers, as described in the MultiplayerSpawner signal description.")
	if node is Player:
		assert(player_nodes.has(node.peer_id), "in _on_entity_despawned(), the deleted player should still be in the player_nodes dict!")
		player_nodes.erase(node.peer_id)
