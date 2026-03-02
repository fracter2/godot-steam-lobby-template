extends Node2D


@export_group("References")
@export var player_spawner: MultiplayerSpawner
@export var player_branches: Node2D

const PLAYER_BRANCH = preload(PATHS.NETWORK_PLAYER_BRANCH)

var player_nodes: Dictionary[int, PlayerBranch] = {}


#
# ---- PROCEDURE ----
#

func _ready() -> void:
	Lobby.lobby_entered.connect(_on_lobby_entered)										# NOTE Local lobby_entered only
	Lobby.lobby_exiting.connect(_on_lobby_exiting)	#, ConnectFlags.CONNECT_DEFERRED # NOTE Deffered to avouid quitting in the middle of processing... Theoretically helpfull

	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.server_disconnected.connect(_on_lobby_exiting.bind("Server disconnected"))

	# NOTE MultiplayerSpawner soawned and despawned signals only emit on remote peers... so non-server clients
	player_spawner.spawned.connect(_check_if_player_spawned)
	player_spawner.despawned.connect(_check_if_player_despawned)

	if Lobby.is_in_lobby():
		_on_lobby_entered()
	else:
		push_warning("Started game without being in a lobby! Is this ok?")
		# NOTE Lobby.lobby_entered will emit after entering a lobby, with the same callback _on_connected()


func _exit_tree() -> void:
	# TODO NOTIFY SERVER BY DISCONNECTING FORMALLY (THROUGH LOBBY MAYBE?)
	#multiplayer.disconnect() # NOTE NOT THIS, SINCE THE SAME PEER IS USED FOR LOBBY!
	# NOTE Some errors may appear of "on_sync_recieve: Ignoring sync data from non-authority or for missing node". THIS IS OK! WE ARE QUITTING! LOL
	pass

#
# ---- SIGNALS ----
#

func _on_lobby_entered() -> void:
	Log.pprint("GAME: JUST JOINED AS PEER %d" % [multiplayer.get_unique_id()])
	multiplayer.multiplayer_peer = Lobby.multiplayer.multiplayer_peer
	assert(multiplayer.multiplayer_peer != null, "obviously this shoulda not be null")
	if multiplayer.is_server():
		_spawn_player(1)	# NOTE 1 is always the server peer_id


func _on_lobby_exiting(message: String) -> void:
	Log.pprint("Quit level, message: %s" % message)
	if is_inside_tree():
		get_tree().change_scene_to_file(PATHS.MAIN_MENU)


func _on_peer_connected(peer_id: int) -> void:
	if multiplayer.is_server():
		_spawn_player(peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
	Log.pprint("GAME: PEER %d DISCONNECTED" % peer_id)
	if multiplayer == null: return 		# NOTE When host disconnectes and the scene changes through _on_lobby_exiting(), this callback still remains, and multiplayer is set to null.
	#Log.pprint("Peer_%d: calling _on_peer_disconnected() on peer_%d" % [multiplayer.get_unique_id(), peer_id])
	if multiplayer.is_server():
		if not player_nodes.has(peer_id):
			push_warning("Peer disconnected but was not added to player_info anyway...")
			return
		player_nodes[peer_id].queue_free()
		player_nodes.erase(peer_id)												# NOTE player_nodes is kept synced on remote peers by the MultiplayerSpawner signal callbacks


## Adds the node to [member player_nodes] if it is a [Player]
func _check_if_player_spawned(node: Node) -> void:
	assert(not multiplayer.is_server(), "_on_entity_spawned() should only be called by non-servers, as described in the MultiplayerSpawner signal description.")
	if node is PlayerBranch:
		var peer_id: int = (node as PlayerBranch).peer_id

		assert(not player_nodes.has(peer_id), "in _on_entity_spawned(), a new player node shouldn't already be registered here. obviously.")
		player_nodes[peer_id] = node

## Removes the node from [member player_nodes] if it is a [Player]
func _check_if_player_despawned(node: Node) -> void:
	assert(not multiplayer.is_server(), "_on_entity_despawned() should only be called by non-servers, as described in the MultiplayerSpawner signal description.")
	if node is PlayerBranch:
		var peer_id: int = (node as PlayerBranch).peer_id
		assert(player_nodes.has(peer_id), "in _on_entity_despawned(), the deleted player should still be in the player_nodes dict!")
		player_nodes.erase(peer_id)


#
# ---- INTERNALS ----
#

func _spawn_player(id: int) -> void:
	assert(multiplayer.is_server())
	assert(not player_nodes.has(id), "in _spawn_player() Spawning a player that is already registered!")

	var player_instance: PlayerBranch = PLAYER_BRANCH.instantiate()
	player_instance.name = "player_peer_%d" % id
	player_instance.peer_id = id
	player_nodes[id] = player_instance											# NOTE player_nodes is kept synced on remote peers by the MultiplayerSpawner signal callbacks
	player_branches.add_child(player_instance)
