class_name PlayerBranchManager
extends Node2D


const PLAYER_BRANCH = preload(PATHS.NETWORK_PLAYER_BRANCH)
var branches: Dictionary[int, PlayerBranch] = {}
var branch_spawner: MultiplayerSpawner											# NOTE Kept synced on remote peers by the MultiplayerSpawner


#
# ---- API ----
#

func get_player_branch_of_unchecked(node: Node) -> PlayerBranch:
	var branch_name: StringName = get_path_to(node).get_name(0)
	return get_node_or_null(NodePath(branch_name))


#
# ---- Procedure ----
#

func _enter_tree() -> void:
	_add_multiplayer_spawner()
	get_tree().node_added.connect(_check_player_ownership)
	if Lobby.is_in_lobby():
		_connect_signals()
	else:
		Lobby.lobby_entered.connect(_connect_signals, ConnectFlags.CONNECT_ONE_SHOT)				# Oneshot to clarify use-case


func _ready() -> void:
	pass


#
# ---- Internal ----
#

func _add_multiplayer_spawner() -> void:
	var spawner: MultiplayerSpawner = MultiplayerSpawner.new()
	spawner.name = "PlayerBranchSpawner"
	spawner.spawn_path = NodePath("..")
	spawner.add_spawnable_scene(PATHS.NETWORK_PLAYER_BRANCH)
	add_child(spawner, true)
	branch_spawner = spawner


func _connect_signals() -> void:
	if multiplayer.is_server():
		_create_branch(1)													# NOTE 1 is always the server peer_id
		multiplayer.peer_connected.connect(_create_branch)
		multiplayer.peer_disconnected.connect(_remove_branch)
	else:
		# NOTE MultiplayerSpawner soawned and despawned signals only emit on remote peers... so non-server clients
		branch_spawner.spawned.connect(_add_branch_to_list)
		branch_spawner.despawned.connect(_remove_branch_from_list)


func _check_player_ownership(node: Node) -> void:
	var is_player_owned: bool = false
	var recursive: bool = false

	if node.is_in_group(GROUPS.PLAYER_OWNED_RECURSIVE):
		is_player_owned = true
		recursive = true
	elif node.is_in_group(GROUPS.PLAYER_OWNED):
		is_player_owned = true

	if is_player_owned and is_ancestor_of(node):
		node.set_multiplayer_authority(get_player_branch_of_unchecked(node).peer_id, recursive)


#
# ---- SERVER ONLY ----
#

func _create_branch(id: int) -> void:
	assert(multiplayer.is_server())
	assert(not branches.has(id), "in _spawn_player_branch() Spawning a player that is already registered!")

	var player_instance: PlayerBranch = PLAYER_BRANCH.instantiate()
	player_instance.name = "player_peer_%d" % id
	player_instance.peer_id = id
	branches[id] = player_instance										# NOTE player_nodes is kept synced on remote peers by the MultiplayerSpawner signal callbacks
	add_child(player_instance)


func _remove_branch(peer_id: int) -> void:
	#Log.pprint("GAME: PEER %d DISCONNECTED" % peer_id)
	if multiplayer == null:
		push_warning("attempt to remove branch when multiplayer == null! Should disconnect signal here!!")	# TODO Replace with signal disconnect where it makes sense, or keep without warning
		return

	assert(multiplayer.is_server())
	assert(branches.has(peer_id), "Peer disconnected but was not added to player_info anyway...")
	branches[peer_id].queue_free()
	branches.erase(peer_id)


#
# ---- CLIENTS ONLY ----
#

func _add_branch_to_list(node: Node) -> void:
	assert(not multiplayer.is_server(), "_on_entity_spawned() should only be called by non-servers, as described in the MultiplayerSpawner signal description.")
	if node is PlayerBranch:
		var peer_id: int = (node as PlayerBranch).peer_id
		assert(not branches.has(peer_id), "in _on_entity_spawned(), duplicate player branch spawned!")
		branches[peer_id] = node


func _remove_branch_from_list(node: Node) -> void:
	assert(not multiplayer.is_server(), "_on_entity_despawned() should only be called by non-servers, as described in the MultiplayerSpawner signal description.")
	if node is PlayerBranch:
		var peer_id: int = (node as PlayerBranch).peer_id
		assert(branches.has(peer_id), "in _on_entity_despawned(), the deleted player should still be in the player_nodes dict!")
		branches.erase(peer_id)
