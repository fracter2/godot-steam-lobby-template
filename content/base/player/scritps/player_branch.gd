class_name PlayerBranch
extends Node2D


const player_character_preload: PackedScene = preload(PATHS.ENTITY_PLAYER_CHARACTER)

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


## Emits when [member peer_id] is set, before or during _enter_tree().
signal setting_peer_authority(peer_id: int)

#
# ---- PROCEDURE ----
#

func _enter_tree() -> void:
	if not Lobby.players.has(peer_id):											# TODO Make lobby assure that this always gets made before signal callbacks
		push_error("PlayerBranch at %s \n -> peer_id %d set but player_info not found!" % [get_path(), peer_id])



func _ready() -> void:
	if player_info == null:
		push_error("Player entity at %s is missing player_info on _enter_tree()!" % get_path())

	if owned_entities.is_multiplayer_authority():
		var character: PlayerCharacter = player_character_preload.instantiate()			# TODO CONSIDER DELEGATING to level specific implementaiton...
		spawn_node(character)

#
# ---- API ----
#

func spawn_node(node: Node) -> void:
	assert(owned_entities.is_multiplayer_authority())
	owned_entities.add_child(node, true)



#
# ---- INTERNAL ----
#
