class_name PlayerBranch
extends Node2D


## Emits when [member peer_id] is set, before or during _enter_tree().
signal setting_peer_authority(peer_id: int)

## The multiplayer peer id assosiated with this player. Setting this also sets the multiplayer authority of
## all nodes in [member player_owned_nodes] on spawn, as well as emitting [signal setting_peer_authority].
@export var peer_id: int = 1:
	set(id):
		peer_id = id
		player_info = Lobby.players.get(id)
		player_owned_spawner.set_multiplayer_authority(id)
		owned_entities.set_multiplayer_authority(id)
		setting_peer_authority.emit(id)

@export_group("References")
@export var player_owned_spawner: MultiplayerSpawner
@export var owned_entities: Node2D

var player_info: PlayerInfo = null




#
# ---- PROCEDURE ----
#

func _enter_tree() -> void:
	if not Lobby.players.has(peer_id):											# TODO Make lobby assure that this always gets made before signal callbacks
		push_error("PlayerBranch at %s \n -> peer_id %d set but player_info not found!" % [get_path(), peer_id])



func _ready() -> void:
	if player_info == null:
		push_error("Player entity at %s is missing player_info on _enter_tree()!" % get_path())


#
# ---- API ----
#

## Spawns a networked node that this player owns, rather than the server. As such it is removed when the player exits. [br]
## Only use if you know this is exacly what you need. Prefer server-side spawning with prediction/reconsiliation, or local spawning (client-side only). [br]
## Especially with physics nodes, as the network latency will be applied to collissions. Or any task in which you cannot trust the client (which is most things). [br]
## Example uses may be markers on a map, or spectator ghost. Notice that most use-cases can be replaced with server-side spawning and prediction logic.
func spawn_node(node: Node) -> void:
	assert(owned_entities.is_multiplayer_authority())
	owned_entities.add_child(node, true)
	# TODO BUG IS THIS NOT AT RISK OF LETTING node BE SERVER AUTHORITY?


#
# ---- INTERNAL ----
#
