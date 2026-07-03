class_name ClientSpawnerManager
extends Node

# TODO RENAME SOURCE FOLDER TO spawn_managers

## The root of all generated player branches. If left empty, will create one automaticallty as a sibling based on parent type (NOTE only Node2D, Node3D, and Node)
@export var branch_root: Node
var branches: Dictionary[int, ClientSpawner] = {}

@export var spawnable_scenes: Spawnlist
# TODO WHEN SET, IF THERE ARE ALREADY BRANCHES SPAWNED (&& is server), RESET THEM WITH NEW SPAWNLIST

const auto_root_name: String = "ClientSpawnerRoot"
const auto_branch_name: String = "Peer_%d"
const auto_branch_spawner_name: String = "ClientSpawner"
static var singleton: ClientSpawnerManager = null


#
# ---- API ----
#

static func is_available() -> bool:
	return singleton != null


static func get_singleton() -> ClientSpawnerManager:
	return singleton


## Returns the local users [ClientSpawner].
static func get_user_spawner() -> ClientSpawner:
	return singleton.branches[singleton.multiplayer.get_unique_id()]


## Get's the [ClientSpawner] that spawned this node. Otherwise returns [code] null [/code].
static func get_spawner_of(node: Node) -> ClientSpawner:
	if not singleton.branch_root.is_ancestor_of(node):
		return null
	var branch_name: StringName = singleton.branch_root.get_path_to(node).get_name(0)
	return singleton.branch_root.get_node_or_null(NodePath(str(branch_name) + "/" + auto_branch_spawner_name))		# WARNING EXPECTS BRANCH SPAWNER TO HAVE CONSISTENT NAME, consider metadata instead


## Adds the node to the tree under the local users [ClientSpawner].
## This means They can have client multiplayer authority, like if [param node] has [constant GROUPS.SET_PLAYER_AUTHORITY] is set.
## The host also has their own one, so all players can be treated the same.
static func spawn(node: Node) -> void:
	# TODO FIX, by adding convenience func to Spawnlist
	#if OS.is_debug_build() and not singleton.spawnable_scenes.list.has(node.scene_file_path):
	#	push_warning("Trying to spawn a node that is not in the spawnlist!! scenepath: " + str(node.scene_file_path) + "\nCallstack: " + str(get_stack()))

	var spawner: ClientSpawner = singleton.branches[singleton.multiplayer.get_unique_id()]
	spawner.spawn_node(node)



#@rpc("authority", "call_local", "reliable")
#func reset_branches_with_new_spawnlist(new_spawnlist: Spawnlist) -> void:
	# TODO apply new spawnlist to ClientSpawnerManager
	# TODO remove existing spawnconfigs from branches
	# TODO add new from spawnlist
	# TODO remove all non-spawnable scenes on replicated peers (so, not from each clients own branch). TEST is this automatic when removing configs?


#
# ---- Procedure ----
#

func _enter_tree() -> void:
	assert(singleton == null)
	singleton = self

	multiplayer.peer_connected.connect(_create_branch)
	multiplayer.peer_disconnected.connect(_remove_branch)

	if not branch_root:
		_create_root.call_deferred(_get_node_instance_from_type(get_parent()))	# NOTE Deffered since cannot spawn during _enter_tree()

	for id: int in multiplayer.get_peers():
		_create_branch.call_deferred(id)
	_create_branch.call_deferred(multiplayer.get_unique_id())


func _exit_tree() -> void:
	singleton = null

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
	assert(branch_root.is_inside_tree())


func _create_branch(id: int) -> void:
	assert(not branches.has(id), "in _spawn_player_branch() Spawning a player that is already registered!")

	var new_branch: Node = _get_node_instance_from_type(branch_root)
	new_branch.name = auto_branch_name % id
	branch_root.add_child(new_branch)

	var new_branch_spawner: ClientSpawner = ClientSpawner.new()
	new_branch_spawner.name = auto_branch_spawner_name
	new_branch_spawner.peer_id = id
	_set_spawnable_scenes(new_branch_spawner, spawnable_scenes.list)
	branches[id] = new_branch_spawner
	branches.sort()
	new_branch.add_child(new_branch_spawner)														# TODO PUT SPAWNERS DIRECTLY AS CHILD HERE (consice list, leaves client spawn paths clear!)

	branch_root.move_child(new_branch, branches.keys().bsearch(new_branch_spawner.peer_id))
	assert(new_branch_spawner.name == auto_branch_spawner_name)										# NOTE used for finding spawner from path

	# In case we ever delete branch spawner, and forget to delete the actuall root node
	new_branch_spawner.tree_exited.connect(new_branch.queue_free)


func _remove_branch(peer_id: int) -> void:
	if multiplayer == null:
		push_warning("attempt to remove branch when multiplayer == null! Should disconnect signal here!!")	# TODO Replace with signal disconnect where it makes sense, or keep without warning
		return

	assert(branches.has(peer_id), "Peer disconnected but was not added to player_info anyway...")
	branches[peer_id].spawn_path_node.queue_free()
	branches.erase(peer_id)


func _set_spawnable_scenes(spawner: MultiplayerSpawner, new_spawnlist: PackedStringArray) -> void:
	# compare with already set paths
	if spawner.get_spawnable_scene_count():
		assert(spawner.is_inside_tree())
		var removed_scenes: PackedStringArray = []
		for i: int in range(spawner.get_spawnable_scene_count()):
			if not new_spawnlist.has(spawner.get_spawnable_scene(i)):
				removed_scenes.push_back(spawner.get_spawnable_scene(i))

		# Despawn nodes that were removed
		for n:Node in get_node(spawner.spawn_path).get_children():
			if removed_scenes.has(n.scene_file_path):
				n.queue_free()

	# Set new spawnable scenes
	spawner.clear_spawnable_scenes()
	for path: String in spawnable_scenes.get_paths_without_invalid():
		spawner.add_spawnable_scene(path)
