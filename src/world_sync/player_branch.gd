class_name PlayerBranch
extends MultiplayerSpawner


## The multiplayer peer id assosiated with this player. Setting this also sets the multiplayer authority of
## all nodes in [member player_owned_nodes] on spawn, as well as emitting [signal setting_peer_authority].
@export var peer_id: int = 1:
	set(id):
		if Lobby.players.has(id):	# TODO CONSIDER REMOVING, ALREADY CHECKED IN _enter_tree()
			peer_id = id
		else:
			push_error("PlayerBranch set to non-existent peer id: " + str(id))
			peer_id = 1
		player_info = Lobby.players.get(peer_id)
		if is_inside_tree():		# TODO Consider removing, redundant with _enter_tree()?
			spawn_path_node = get_node_or_null(spawn_path)
			if spawn_path_node != null:
				get_node_or_null(spawn_path).set_multiplayer_authority(peer_id)


var player_info: PlayerInfo = null
var spawn_path_node: Node

#
# ---- PROCEDURE ----
#

func _enter_tree() -> void:
	if not Lobby.players.has(peer_id):											# TODO Make lobby assure that this always gets made before signal callbacks
		push_error("PlayerBranch at %s \n -> peer_id %d set but player_info not found!" % [get_path(), peer_id])

	if spawn_path.is_empty():
		spawn_path = get_path_to(get_parent())
		spawn_path_node = get_parent()

	if spawn_path_node != null:
		spawn_path_node.set_multiplayer_authority(peer_id)
	else:
		push_error("PlayerBranch at %s \n -> spawn_path %s set but node not found!" % [get_path(), spawn_path])



func _ready() -> void:
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

	# TODO BUG IS THIS NOT AT RISK OF LETTING node BE SERVER AUTHORITY?
	# TEST IF SPAWNING SERVER NODES OK?
	# TODO DECIDE IF THAT IS INTENDED BEHAVIOUR

	# TODO CONSIDER PUSHING WARNING IF IT IS NOT PEER AUTHORITATIVE


#
# ---- INTERNAL ----
#
