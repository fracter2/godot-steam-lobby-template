class_name LocalSpawnManager
extends Node

const default_root_name: String = "LocalSpawnRoot"
static var singleton: LocalSpawnManager = null

## The root of all spawned nodes. If left empty, will create one automaticallty as a sibling based on parent type (NOTE only Node2D, Node3D, and Node)
@export var spawn_root: Node


#
# ---- API ----
#

static func is_available() -> bool:
	return singleton != null


static func get_singleton() -> LocalSpawnManager:
	return singleton


## Spawns the node as a client-side only object, meaning it's only spawned for the local user. [br]
## Functionally the same as just calling [method add_child()] to [member spawn_root], with no Multiplayer funny buissness. [br]
## Since there is no multiplayer involved, there are no restrictions.
static func spawn(node: Node) -> void:
	singleton.spawn_root.add_child(node, true)



#
# ---- Procedure ----
#

func _enter_tree() -> void:
	assert(singleton == null)
	singleton = self

	if not spawn_root:
		_create_root.call_deferred(_get_node_instance_from_type(get_parent()))	# NOTE Deffered since cannot spawn during _enter_tree()


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
