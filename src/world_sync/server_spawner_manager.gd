class_name ServerSpawnerManager
extends Node

# TODO make singleton

## The root of all generated player branches. If left empty, will create one automaticallty as a sibling based on parent type (NOTE only Node2D, Node3D, and Node)
@export var spawn_root: Node

# TODO WHEN SET, IF THERE ARE ALREADY BRANCHES SPAWNED (&& is server), RESET THEM WITH NEW SPAWNLIST
@export var spawnable_scenes: Spawnlist

const auto_root_name: String = "ServerBranch"
const auto_spawner_name: String = "ServerBranchSpawner"
static var singleton: ServerSpawnerManager = null

var spawner: MultiplayerSpawner


#
# ---- API ----
#

## Adds the node to the tree under [property server_branch], of course with server authority set.
static func spawn(node: Node) -> void:
	if not singleton.multiplayer.is_server():
		push_error("Cannot spawn server entities as client! Called from: " + str(get_stack()))
		breakpoint
		return

	# TODO FIX, by adding convenience func to Spawnlist
	#if OS.is_debug_build() and not singleton.spawnable_scenes.list.has(node.scene_file_path):
	#	push_warning("Trying to spawn a node that is not in the spawnlist!! scenepath: " + str(node.scene_file_path) + "\nCallstack: " + str(get_stack()))

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

	assert(spawner == null)
	spawner = MultiplayerSpawner.new()
	spawner.name = auto_spawner_name
	for path: String in spawnable_scenes.get_paths_without_invalid():
		spawner.add_spawnable_scene(path)
	add_child(spawner, true)
