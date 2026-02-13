extends Node2D


@onready var player_spawner: MultiplayerSpawner = $PlayerSpawner
@onready var players: Node2D = $Players

var main_menu_preload : PackedScene = preload(PATHS.MAIN_MENU)
const PLAYER_ENTITY_PRELOAD = preload(PATHS.PLAYER_ENTITY)

var player_nodes: Dictionary[int, PlayerEntity] = {}


#
# ---- PROCEDURE ----
#

func _ready() -> void:
	Lobby.lobby_entered.connect(_on_connected)										# NOTE Local lobby_entered only
	Lobby.lobby_exiting.connect(_on_lobby_exiting, ConnectFlags.CONNECT_DEFERRED)	# NOTE Deffered to avouid quitting in the middle of processing... Theoretically helpfull

	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	# NOTE MultiplayerSpawner soawned and despawned signals only emit on remote peers... so non-server clients
	player_spawner.spawned.connect(_check_if_player_spawned)
	player_spawner.despawned.connect(_check_if_player_despawned)

	if Lobby.is_in_lobby():
		_on_connected()
	else:
		push_warning("Started game without being in a lobby! Is this ok?")
		# NOTE Lobby.lobby_entered will emit after entering a lobby, with the same callback _on_connected()


#
# ---- SIGNALS ----
#

func _on_connected() -> void:
	print("Peer_%d: Lobby connected, setting game multiplayer authority" % multiplayer.get_unique_id())
	multiplayer.multiplayer_peer = Lobby.multiplayer.multiplayer_peer
	assert(multiplayer.multiplayer_peer != null, "obviously this shoulda not be null")
	if multiplayer.is_server():
		_spawn_player(1)	# NOTE 1 is always the server peer_id


func _on_lobby_exiting(message: String) -> void:
	print("Peer_%d: Quit level, message: %s" % [multiplayer.get_unique_id(), message])
	get_tree().change_scene_to_file(PATHS.MAIN_MENU)


func _on_peer_connected(peer_id: int) -> void:
	print("Peer_%d: Peer connected with id: %d" % [multiplayer.get_unique_id(), peer_id])
	if multiplayer.is_server():
		_spawn_player(peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
	print("Peer_%d: calling _on_peer_disconnected() on peer_%d" % [multiplayer.get_unique_id(), peer_id])
	if multiplayer.is_server():
		if not player_nodes.has(peer_id):
			push_warning("Peer disconnected but was not added to player_info anyway...")
			return
		player_nodes[peer_id].queue_free()
		player_nodes.erase(peer_id)												# NOTE player_nodes is kept synced on remote peers by the MultiplayerSpawner signal callbacks


## Adds the node to [member player_nodes] if it is a [Player]
func _check_if_player_spawned(node: Node) -> void:
	assert(not multiplayer.is_server(), "_on_entity_spawned() should only be called by non-servers, as described in the MultiplayerSpawner signal description.")
	if node is PlayerEntity:
		var peer_id: int = (node as PlayerEntity).peer_id
		print("Peer_%d: calling _check_if_player_spawned() on peer_%d" % [multiplayer.get_unique_id(), peer_id])
		assert(not player_nodes.has(peer_id), "in _on_entity_spawned(), a new player node shouldn't already be registered here. obviously.")
		player_nodes[peer_id] = node

## Removes the node from [member player_nodes] if it is a [Player]
func _check_if_player_despawned(node: Node) -> void:
	assert(not multiplayer.is_server(), "_on_entity_despawned() should only be called by non-servers, as described in the MultiplayerSpawner signal description.")
	if node is PlayerEntity:
		var peer_id: int = (node as PlayerEntity).peer_id
		assert(player_nodes.has(peer_id), "in _on_entity_despawned(), the deleted player should still be in the player_nodes dict!")
		player_nodes.erase(peer_id)


#
# ---- INTERNALS ----
#

func _spawn_player(id: int) -> void:
	assert(multiplayer.is_server())
	assert(not player_nodes.has(id), "in _spawn_player() Spawning a player that is already registered!")
	print("Peer_%d: calling _spawn_player(%d)" % [multiplayer.get_unique_id(), id])

	var player_instance: PlayerEntity = PLAYER_ENTITY_PRELOAD.instantiate()
	player_instance.name = "player_peer_%d" % id
	player_instance.peer_id = id
	player_nodes[id] = player_instance											# NOTE player_nodes is kept synced on remote peers by the MultiplayerSpawner signal callbacks
	players.add_child(player_instance)
