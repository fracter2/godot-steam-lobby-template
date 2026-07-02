class_name PlayerBranchManager
extends Node

# TODO RENAME TO ClientSpawner OR ClientSpawnManager
# TODO make singleton
# TODO RENAME SOURCE FOLDER TO spawn_managers

## The root of all generated player branches. If left empty, will create one automaticallty as a sibling based on parent type (NOTE only Node2D, Node3D, and Node)
@export var branch_root: Node
var branches: Dictionary[int, PlayerBranch] = {}

@export var spawnable_scenes: Spawnlist

const auto_root_name: String = "PlayerBranches"

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
	multiplayer.peer_connected.connect(_create_branch)
	multiplayer.peer_disconnected.connect(_remove_branch)

	if not branch_root:
		_create_root(_get_node_instance_from_type(get_parent()))

	for id: int in multiplayer.get_peers():
		_create_branch(id)
	_create_branch(multiplayer.get_unique_id())


#
# ---- Internal ----
#

## The point of assigning Node2D / Node3D as appropriate is to not interrupt accending / inheriting hierarchies of properties, like visibility. [br]
## Though I have not tested if it actually makes a difference in any meaningfull scenario.
func _get_node_instance_from_type(from_node: Node) -> Node:
	if from_node is Node2D: return Node2D.new()
	if from_node is Node3D: return Node3D.new()
	else: 					return Node.new()





func _create_root(new_root: Node) -> void:
	new_root.name = auto_root_name
	add_sibling(new_root, true)
	branch_root = new_root


func _create_branch(id: int) -> void:
	assert(not branches.has(id), "in _spawn_player_branch() Spawning a player that is already registered!")

	var new_branch: Node = _get_node_instance_from_type(branch_root)
	new_branch.name = "player_peer_%d" % id
	add_child(new_branch)

	var new_branch_spawner: PlayerBranch = PlayerBranch.new()
	new_branch_spawner.name = "PlayerOwnedSpawner"
	new_branch_spawner.peer_id = id
	_set_spawnable_scenes(new_branch_spawner)
	branches[id] = new_branch_spawner
	branches.sort()
	new_branch.add_child(new_branch_spawner)
	move_child(new_branch, branches.keys().bsearch(new_branch_spawner.peer_id))

	# In case we ever delete branch, and forget to delete the actually player-owned nodes
	new_branch_spawner.tree_exited.connect(new_branch.queue_free)


func _remove_branch(peer_id: int) -> void:
	#Log.pprint("GAME: PEER %d DISCONNECTED" % peer_id)
	if multiplayer == null:
		push_warning("attempt to remove branch when multiplayer == null! Should disconnect signal here!!")	# TODO Replace with signal disconnect where it makes sense, or keep without warning
		return

	assert(branches.has(peer_id), "Peer disconnected but was not added to player_info anyway...")
	branches[peer_id].spawn_path_node.queue_free()
	branches.erase(peer_id)


func _set_spawnable_scenes(spawner: PlayerBranch) -> void:
	for path: String in spawnable_scenes.get_paths_without_invalid():
		spawner.add_spawnable_scene(path)
