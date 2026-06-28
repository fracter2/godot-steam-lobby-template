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
	get_tree().node_added.connect(_check_player_ownership)
	multiplayer.peer_connected.connect(_create_branch)
	multiplayer.peer_disconnected.connect(_remove_branch)
	for id: int in multiplayer.get_peers():
		_create_branch(id)
	_create_branch(multiplayer.get_unique_id())


#
# ---- Internal ----
#

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


func _create_branch(id: int) -> void:
	assert(not branches.has(id), "in _spawn_player_branch() Spawning a player that is already registered!")

	var branch_instance: PlayerBranch = PLAYER_BRANCH.instantiate()
	branch_instance.name = "player_peer_%d" % id
	branch_instance.peer_id = id
	branches[id] = branch_instance
	add_child(branch_instance)
	branches.sort()
	move_child(branch_instance, branches.keys().bsearch(branch_instance.peer_id))


func _remove_branch(peer_id: int) -> void:
	#Log.pprint("GAME: PEER %d DISCONNECTED" % peer_id)
	if multiplayer == null:
		push_warning("attempt to remove branch when multiplayer == null! Should disconnect signal here!!")	# TODO Replace with signal disconnect where it makes sense, or keep without warning
		return

	assert(multiplayer.is_server())
	assert(branches.has(peer_id), "Peer disconnected but was not added to player_info anyway...")
	branches[peer_id].queue_free()
	branches.erase(peer_id)
