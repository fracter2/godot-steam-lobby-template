class_name PlayerBranch
extends MultiplayerSpawner


## The multiplayer peer id assosiated with this player. Setting this also sets the multiplayer authority of
## all nodes in [member player_owned_nodes] on spawn, as well as emitting [signal setting_peer_authority].
@export var peer_id: int = 1:
	set(id):
		assert(not is_inside_tree(), "PlayerBranch nodes are only meant to support one peer for it's lifetime, so not reassignable.")
		if Lobby.players.has(id):	# TODO CONSIDER REMOVING, ALREADY CHECKED IN _enter_tree()
			peer_id = id
		else:
			push_error("PlayerBranch set to non-existent peer id: " + str(id))
			peer_id = 1
		player_info = Lobby.players.get(peer_id)


var player_info: PlayerInfo = null
var spawn_path_node: Node

#
# ---- PROCEDURE ----
#

func _enter_tree() -> void:
	if not Lobby.players.has(peer_id):											# TODO Make lobby assure that this always gets made before signal callbacks
		push_error("PlayerBranch at %s \n -> peer_id %d set but player_info not found!" % [get_path(), peer_id])

	spawn_path = get_path_to(get_parent())
	spawn_path_node = get_parent()
	spawn_path_node.set_multiplayer_authority(peer_id)
	assert(get_multiplayer_authority() == peer_id)


func _ready() -> void:
	spawn_path_node.child_entered_tree.connect(_search_when_ready)

	if player_info == null:
		push_error("Player entity at %s is missing player_info on _enter_tree()!" % get_path())


#
# ---- API ----
#

## Spawns a networked node on this player branch. [br]
## It is intended to allow simple player-driven actions without having to manage prediction, at the cost of trusting the client. [br]
## Prefer server-side spawning with prediction/reconsiliation, or local spawning (which is client-side only). [br]
## Especially with physics nodes, as the network latency will be applied to collissions. Or any task in which you cannot trust the client (which is most things). [br]
## Example uses may be markers on a map, or spectator ghost. Most use-cases can be replaced with server-side spawning and prediction logic.
func spawn_node(node: Node) -> void:
	assert(spawn_path_node.is_multiplayer_authority())
	spawn_path_node.add_child(node, true)

	# TEST IF IT CAN REPLICATE SERVER-OWNED NODES
	# IF YES, LET SERVER-AUTH BE DEFAULT + GROUPS


#
# ---- INTERNAL ----
#

## We wait for the very last node in this group to emit [method _enter_tree], as it is JUST BEFORE they start being [method _ready].
## This let's the nodes scripts reliably check multiplayer authority in their [method _ready] funcs.
## This also let's us simplify the group-checks as all children will be added to the [method get_tree().get_nodes_in_group]
func _search_when_ready(new_child: Node) -> void:
	var deepest_node: Node = new_child
	while deepest_node.get_child_count() != 0:
		deepest_node = deepest_node.get_child(-1)
	deepest_node.tree_entered.connect(_search_all_in_groups, CONNECT_ONE_SHOT)


func _search_all_in_groups() -> void:
	var groups_nodes: Array[Node] = get_tree().get_nodes_in_group(GROUPS.SET_PLAYER_AUTHORITY)
	groups_nodes.append_array(get_tree().get_nodes_in_group(GROUPS.SET_SERVER_AUTHORITY))
	groups_nodes.append_array(get_tree().get_nodes_in_group(GROUPS.SET_PLAYER_AUTHORITY_NO_CHILDREN))
	groups_nodes.append_array(get_tree().get_nodes_in_group(GROUPS.SET_SERVER_AUTHORITY_NO_CHILDREN))

	# CHECK THEM (ignore if they path to another branch... just remove if server_auth on non-branch...)
	var branch_nodes: Array[Node] = []
	var irrelevant_nodes: Array[Node] = []
	for n: Node in groups_nodes:
		if spawn_path_node.is_ancestor_of(n):
			branch_nodes.push_back(n)
		elif not spawn_path_node.get_parent().is_ancestor_of(n):
			irrelevant_nodes.push_back(n)

	# Strip groups from all nodes not in player branches (they serve no purpose)
	for n: Node in irrelevant_nodes:
		n.remove_from_group(GROUPS.SET_PLAYER_AUTHORITY)
		n.remove_from_group(GROUPS.SET_SERVER_AUTHORITY)
		n.remove_from_group(GROUPS.SET_PLAYER_AUTHORITY_NO_CHILDREN)
		n.remove_from_group(GROUPS.SET_SERVER_AUTHORITY_NO_CHILDREN)

	# Apply and remove groups, according to tree hierarchy (to let child-nodes to override recursive parents)
	branch_nodes.sort_custom(_search_algorithm)
	for n: Node in branch_nodes:
		_check_and_apply_authority_groups(n)


## Short node paths come first
func _search_algorithm(a: Node, b: Node) -> bool:
	return a.get_path().get_name_count() < b.get_path().get_name_count()


##
func _check_and_apply_authority_groups(node: Node) -> void:
	if node.is_in_group		  (GROUPS.SET_PLAYER_AUTHORITY):
		node.remove_from_group(GROUPS.SET_PLAYER_AUTHORITY)
		node.set_multiplayer_authority(peer_id, true)

	if node.is_in_group		  (GROUPS.SET_SERVER_AUTHORITY):
		node.remove_from_group(GROUPS.SET_SERVER_AUTHORITY)
		node.set_multiplayer_authority(1, true)

	if node.is_in_group		  (GROUPS.SET_PLAYER_AUTHORITY_NO_CHILDREN):
		node.remove_from_group(GROUPS.SET_PLAYER_AUTHORITY_NO_CHILDREN)
		node.set_multiplayer_authority(peer_id, false)

	if node.is_in_group		  (GROUPS.SET_SERVER_AUTHORITY_NO_CHILDREN):
		node.remove_from_group(GROUPS.SET_SERVER_AUTHORITY_NO_CHILDREN)
		node.set_multiplayer_authority(1, false)
