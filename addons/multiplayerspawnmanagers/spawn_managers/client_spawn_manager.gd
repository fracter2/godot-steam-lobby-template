class_name ClientSpawnManager
extends Node
## Manages client-owned spawning by spawning a unique [ClientSpawner] for each multiplayerpeer connected, that they have authority on. [br]
##
## Authority is not set for spawned entities automatically, unless they are in any of the 4 ClientSpawn Groups.
## The most important functions are [method get_user_spawner], [method get_spawner_of], and [method spawn].
## All spawns are validated through [member spawnable_scenes].

const default_root_name: String = "ClientSpawnRoot"
const default_branch_name: String = "Peer_%d"
const default_branch_spawner_name: String = "ClientSpawner"
static var singleton: ClientSpawnManager = null

## The root of all generated [ClientSpawner]s. If left empty, will create one automaticallty as a sibling based on parent type (NOTE only Node2D, Node3D, and Node)
@export var spawn_root: Node
var client_spawners: Dictionary[int, ClientSpawner] = {}

@export var spawnable_scenes: Spawnlist
# TODO WHEN SET, IF THERE ARE ALREADY BRANCHES SPAWNED (&& is server), RESET THEM WITH NEW SPAWNLIST



#
# ---- API ----
#

static func is_available() -> bool:
	return singleton != null


static func get_singleton() -> ClientSpawnManager:
	return singleton


## Returns the local users [ClientSpawner].
static func get_user_spawner() -> ClientSpawner:
	return singleton.client_spawners[singleton.multiplayer.get_unique_id()]


## Get's the [ClientSpawner] that spawned this node. Otherwise returns [code] null [/code].
static func get_spawner_of(node: Node) -> ClientSpawner:
	if not singleton.spawn_root.is_ancestor_of(node):
		return null
	var branch_name: StringName = singleton.spawn_root.get_path_to(node).get_name(0)
	var branch_id: int = singleton.spawn_root.get_node(NodePath(branch_name)).get_multiplayer_authority()
	return singleton.client_spawners[branch_id]


## Spawns the node with the local users [ClientSpawner] as a synced multiplayer object. [br]
## Not to be confused with [LocalSpawnManager], that handles client-side spawning. [BR]
## This means They can have client multiplayer authority, like if [param node] has [constant GROUPS.CLIENT_SPAWNER_SET_CLIENT_AUTHORITY] is set.
## The host also has their own one, so all players can be treated the same.
static func spawn(node: Node) -> void:
	if OS.is_debug_build() and ((not node.scene_file_path) or not singleton.spawnable_scenes.has_path(node.scene_file_path)):
		push_warning("Trying to spawn a node that is not in the spawnlist!! scenepath: " + str(node.scene_file_path) + "\nCallstack: " + str(get_stack()))

	var spawner: ClientSpawner = singleton.client_spawners[singleton.multiplayer.get_unique_id()]
	spawner.spawn_node(node)



#@rpc("authority", "call_local", "reliable")
#func reset_branches_with_new_spawnlist(new_spawnlist: Spawnlist) -> void:
	# TODO MAKE ONLY CCALLABLE BY SERVER, EVEN LOCALLY
	# TODO apply new spawnlist to ClientSpawnManager for server and all peers
	# TODO use _set_spawnable_scenes on local branch
	# TODO TEST Let other's peer branches be untouched, let the branches call their own de-spawn... TODO CONSIDER MANUAL RPC FROM EACH


#
# ---- Procedure ----
#

func _enter_tree() -> void:
	assert(singleton == null)
	singleton = self

	get_parent().ready.connect(_create_branches, CONNECT_ONE_SHOT)


func _create_branches() -> void:
	multiplayer.peer_connected.connect(_create_branch)
	multiplayer.peer_disconnected.connect(_remove_branch)
	if not spawn_root:
		_create_root(_get_node_instance_from_type(get_parent()))
	for id: int in multiplayer.get_peers():
		_create_branch(id)
	_create_branch(multiplayer.get_unique_id())


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
	new_root.name = default_root_name
	add_sibling(new_root, true)
	spawn_root = new_root
	assert(spawn_root.is_inside_tree())


func _create_branch(id: int) -> void:
	assert(not client_spawners.has(id), "in _spawn_player_branch() Spawning a player that is already registered!")

	var new_branch: Node = _get_node_instance_from_type(spawn_root)
	new_branch.name = default_branch_name % id
	spawn_root.add_child(new_branch)

	var new_branch_spawner: ClientSpawner = ClientSpawner.new()
	new_branch_spawner.name = default_branch_spawner_name
	new_branch_spawner.peer_id = id
	_set_spawnable_scenes(new_branch_spawner, spawnable_scenes)
	client_spawners[id] = new_branch_spawner
	client_spawners.sort()
	new_branch.add_child(new_branch_spawner)														# TODO PUT SPAWNERS DIRECTLY AS CHILD HERE (consice list, leaves client spawn paths clear!)

	spawn_root.move_child(new_branch, client_spawners.keys().bsearch(new_branch_spawner.peer_id))
	assert(new_branch_spawner.name == default_branch_spawner_name)										# NOTE used for finding spawner from path

	# In case we ever delete branch spawner, and forget to delete the actuall root node
	new_branch_spawner.tree_exited.connect(new_branch.queue_free)


func _remove_branch(peer_id: int) -> void:
	if multiplayer == null:
		push_warning("attempt to remove branch when multiplayer == null! Should disconnect signal here!!")	# TODO Replace with signal disconnect where it makes sense, or keep without warning
		return

	assert(client_spawners.has(peer_id), "Peer disconnected but was not added to player_info anyway...")
	client_spawners[peer_id].spawn_path_node.queue_free()
	client_spawners.erase(peer_id)


func _set_spawnable_scenes(spawner: MultiplayerSpawner, new_spawnlist: Spawnlist) -> void:
	# compare with already set paths
	if spawner.get_spawnable_scene_count():
		assert(spawner.is_inside_tree())
		var removed_scenes: PackedStringArray = []
		for i: int in range(spawner.get_spawnable_scene_count()):
			if not new_spawnlist.has_path(spawner.get_spawnable_scene(i)):
				removed_scenes.push_back(spawner.get_spawnable_scene(i))

		# Despawn nodes that were removed
		for n:Node in get_node(spawner.spawn_path).get_children():
			if removed_scenes.has(n.scene_file_path):
				n.queue_free()

	# Set new spawnable scenes
	spawner.clear_spawnable_scenes()
	for path: String in spawnable_scenes.get_valid_paths():
		spawner.add_spawnable_scene(path)
