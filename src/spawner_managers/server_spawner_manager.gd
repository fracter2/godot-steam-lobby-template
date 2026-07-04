class_name ServerSpawnerManager
extends Node


const auto_root_name: String = "ServerBranch"
const auto_spawner_name: String = "ServerBranchSpawner"
static var singleton: ServerSpawnerManager = null

## The root of all generated client spawners. If left empty, will create one automaticallty as a sibling, based on parent type (NOTE only Node2D, Node3D, and Node)
@export var spawn_root: Node

@export var spawnable_scenes: Spawnlist																# TODO WHEN SET, IF THERE ARE ALREADY BRANCHES SPAWNED (&& is server), RESET THEM WITH NEW SPAWNLIST

var server_spawner: MultiplayerSpawner


#
# ---- API ----
#

## Adds the node to the tree under [property server_branch], of course with server authority set.
static func spawn(node: Node) -> void:
	if not singleton.multiplayer.is_server():
		push_error("Cannot spawn server entities as client! Called from: " + str(get_stack()))
		breakpoint
		return

	if OS.is_debug_build() and ((not node.scene_file_path) or not singleton.spawnable_scenes.has_path(node.scene_file_path)):
		push_warning("Trying to spawn a node that is not in the spawnlist!! scenepath: " + str(node.scene_file_path) + "\nCallstack: " + str(get_stack()))

	singleton.spawn_root.add_child(node, true)


#
# ---- Procedure ----
#

func _enter_tree() -> void:
	assert(singleton == null)
	singleton = self

	assert(spawnable_scenes != null, "ServerSpawnerManager is missing a Spawnlist!")

	if not spawn_root:
		_create_root.call_deferred(_get_node_instance_from_type(get_parent()))


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
	assert(spawn_root == null)
	spawn_root = new_root
	spawn_root.name = auto_root_name
	add_sibling(spawn_root, true)

	assert(server_spawner == null)
	server_spawner = MultiplayerSpawner.new()
	server_spawner.name = auto_spawner_name
	for path: String in spawnable_scenes.get_path():
		server_spawner.add_spawnable_scene(path)
	add_child(server_spawner, true)


func _set_spawnable_scenes_and_clean_children(spawner: MultiplayerSpawner, new_spawnlist: Spawnlist) -> void:
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
