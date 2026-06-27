class_name World
extends Node2D


@export_group("References")
@export var player_branch_spawner: MultiplayerSpawner
@export var player_branch_root: Node2D
@export var entity_spawner: MultiplayerSpawner									# TODO RENAME server spawner OR server branch spawner
@export var networked_entities: Node2D											# TODO RENAME server entities OR server branch
@export var local_entities: Node2D												# TODO RENAME local branch

const PLAYER_BRANCH = preload(PATHS.NETWORK_PLAYER_BRANCH)

var player_branches: Dictionary[int, PlayerBranch] = {}

static var singleton: World = null


#
# ---- PROCEDURE ----
#

func _enter_tree() -> void:
	assert(singleton == null)
	singleton = self

	get_tree().node_added.connect(_check_player_ownership)


func _ready() -> void:
	Lobby.lobby_entered.connect(_on_lobby_entered)										# NOTE Local lobby_entered only
	Lobby.lobby_exiting.connect(_on_lobby_exiting)	#, ConnectFlags.CONNECT_DEFERRED # NOTE Deffered to avouid quitting in the middle of processing... Theoretically helpfull

	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.server_disconnected.connect(_on_lobby_exiting.bind("Server disconnected"))

	# NOTE MultiplayerSpawner soawned and despawned signals only emit on remote peers... so non-server clients
	player_branch_spawner.spawned.connect(_check_if_player_spawned)
	player_branch_spawner.despawned.connect(_check_if_player_despawned)

	if Lobby.is_in_lobby():
		_on_lobby_entered()
	else:
		push_warning("Started game without being in a lobby! Is this ok?")
		# NOTE Lobby.lobby_entered will emit after entering a lobby, with the same callback _on_connected()


func _exit_tree() -> void:
	# TODO NOTIFY SERVER BY DISCONNECTING FORMALLY (THROUGH LOBBY MAYBE?)
	#multiplayer.disconnect() # NOTE NOT THIS, SINCE THE SAME PEER IS USED FOR LOBBY!
	# NOTE Some errors may appear of "on_sync_recieve: Ignoring sync data from non-authority or for missing node". THIS IS OK! WE ARE QUITTING! LOL

	singleton = null
	pass


#
# ---- API ----
#

## TODO CONSIDER MOVING ALL PLAYER BRANCH LOGIC TO PLAYER BRANCH SPAWNER NODE!!

static func get_player_branch_of(node: Node) -> PlayerBranch:
	assert(singleton.player_branch_root.is_ancestor_of(node))
	var branch: Node = singleton._get_player_branch_of_unchecked(node)

	if branch == null or not branch is PlayerBranch:
		Log.pprint("ayayaaaa")
		return null

	return branch


## Returns the local users [PlayerBranch].
static func get_user_player_branch() -> PlayerBranch:
	return singleton.player_nodes[singleton.multiplayer.get_unique_id()]


## Adds the node to the tree under [property networked_entities], of course with server authority set.
static func spawn_server_owned(node: Node) -> void:
	singleton.networked_entities.add_child(node)


## Adds the node to the tree under the local users [PlayerBranch], with it's own [MultiplayerSpawner].
## This means They can have client multiplayer authority, like if [param node] has [constant GROUPS.PLAYER_OWNED] is set.
## If called by host, still uses host branch.
static func spawn_client_owned(node: Node) -> void:
	var branch: PlayerBranch = singleton.player_nodes[singleton.multiplayer.get_unique_id()]
	branch.spawn_node(node)


## Adds the node to the tree under [property local_entities]. Note that client-local (aka clientside or client-only) spawns don't
## have a [MultiplayerSpawner] atached, but still has the multiplayer authority set to default (server, id 1).
static func spawn_client_local(node: Node) -> void:
	singleton.local_entities.add_child(node, true)





#
# ---- SIGNALS ----
#

func _on_lobby_entered() -> void:
	Log.pprint("GAME: JUST JOINED AS PEER %d" % [multiplayer.get_unique_id()])
	multiplayer.multiplayer_peer = Lobby.multiplayer.multiplayer_peer
	assert(multiplayer.multiplayer_peer != null, "obviously this shoulda not be null")
	if multiplayer.is_server():
		_spawn_player_branch(1)	# NOTE 1 is always the server peer_id


func _on_lobby_exiting(message: String) -> void:
	Log.pprint("Quit level, message: %s" % message)
	if is_inside_tree():
		get_tree().change_scene_to_file(PATHS.MAIN_MENU)


func _on_peer_connected(peer_id: int) -> void:
	if multiplayer.is_server():
		_spawn_player_branch(peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
	Log.pprint("GAME: PEER %d DISCONNECTED" % peer_id)
	if multiplayer == null: return 		# NOTE When host disconnectes and the scene changes through _on_lobby_exiting(), this callback still remains, and multiplayer is set to null.
	#Log.pprint("Peer_%d: calling _on_peer_disconnected() on peer_%d" % [multiplayer.get_unique_id(), peer_id])
	if multiplayer.is_server():
		if not player_branches.has(peer_id):
			push_warning("Peer disconnected but was not added to player_info anyway...")
			return
		player_branches[peer_id].queue_free()
		player_branches.erase(peer_id)												# NOTE player_nodes is kept synced on remote peers by the MultiplayerSpawner signal callbacks


## Adds the node to [member player_nodes] if it is a [Player]
func _check_if_player_spawned(node: Node) -> void:
	assert(not multiplayer.is_server(), "_on_entity_spawned() should only be called by non-servers, as described in the MultiplayerSpawner signal description.")
	if node is PlayerBranch:
		var peer_id: int = (node as PlayerBranch).peer_id

		assert(not player_branches.has(peer_id), "in _on_entity_spawned(), a new player node shouldn't already be registered here. obviously.")
		player_branches[peer_id] = node

## Removes the node from [member player_nodes] if it is a [Player]
func _check_if_player_despawned(node: Node) -> void:
	assert(not multiplayer.is_server(), "_on_entity_despawned() should only be called by non-servers, as described in the MultiplayerSpawner signal description.")
	if node is PlayerBranch:
		var peer_id: int = (node as PlayerBranch).peer_id
		assert(player_branches.has(peer_id), "in _on_entity_despawned(), the deleted player should still be in the player_nodes dict!")
		player_branches.erase(peer_id)


func _check_player_ownership(node: Node) -> void:
	if node.is_in_group(GROUPS.PLAYER_OWNED_RECURSIVE) and player_branch_root.is_ancestor_of(node):
		node.set_multiplayer_authority(_get_player_branch_of_unchecked(node).peer_id, true)
	elif node.is_in_group(GROUPS.PLAYER_OWNED) and player_branch_root.is_ancestor_of(node):
		node.set_multiplayer_authority(_get_player_branch_of_unchecked(node).peer_id, false)

#
# ---- INTERNALS ----
#

func _spawn_player_branch(id: int) -> void:
	assert(multiplayer.is_server())
	assert(not player_branches.has(id), "in _spawn_player_branch() Spawning a player that is already registered!")

	var player_instance: PlayerBranch = PLAYER_BRANCH.instantiate()
	player_instance.name = "player_peer_%d" % id
	player_instance.peer_id = id
	player_branches[id] = player_instance											# NOTE player_nodes is kept synced on remote peers by the MultiplayerSpawner signal callbacks
	player_branch_root.add_child(player_instance)


func _get_player_branch_of_unchecked(node: Node) -> PlayerBranch:
	var branch_name: StringName = player_branch_root.get_path_to(node).get_name(0)
	return player_branch_root.get_node_or_null(NodePath(branch_name))
