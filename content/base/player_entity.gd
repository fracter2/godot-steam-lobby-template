class_name PlayerEntity															# TODO CONSIDER RENAMING TO PlayerMaster or PlayerBranch
extends Node2D

## The multiplayer peer id assosiated with this player. Setting this also sets the multiplayer authority of
## all nodes in [member player_owned_nodes] on spawn, as well as emitting [signal setting_peer_authority].
@export var peer_id: int = 1:
	set(id):
		peer_id = id
		player_info = Lobby.players.get(id)
		for node in player_owned_nodes:
			node.set_multiplayer_authority(id, false)
		setting_peer_authority.emit(id)


## Nodes that have [method set_multiplayer_authority] set to the peer multiplayer authority. Does NOT propagate to children.
## Only updated on peer_id set, which is before [method _enter_tree]. Right now is not guaranteed to be synced at all.
@export var player_owned_nodes: Array[Node] = []								# TODO Consider exclusively using signal to clarify usage. Does not benefit from a variables.

@export_group("References")
@export var camera_2d: Camera2D
@export var name_label: Label
@export var sprite_2d: Sprite2D


var player_info: PlayerInfo = null:
	set(info):
		_disconnect_player_info(player_info)
		player_info = info
		_connect_player_info(info)

## Emits when [member peer_id] is set, before or during _enter_tree().
signal setting_peer_authority(peer_id: int)

#
# ---- PROCEDURE ----
#

func _enter_tree() -> void:
	if player_info == null:
		push_warning("Player entity at %s is missing player_info on _enter_tree()!" % get_path())

	if not Lobby.players.has(peer_id):
		push_error("PlayerEntity at %s \n -> peer_id %d set but player_info not found!" % [get_path(), peer_id])


func _ready() -> void:
	if multiplayer.get_unique_id() == peer_id:
		camera_2d.enabled = true
		camera_2d.make_current()


#
# ---- SIGNAL CALLBACKS ----
#

func _on_name_set(_new_name: String = "") -> void:
	if not player_info.nickname.is_empty(): 		name_label.text = player_info.nickname
	elif not player_info.display_name.is_empty():	name_label.text = player_info.display_name
	else: 											name_label.text = "DefaultName"


func _on_avatar_set(_new_avatar: Image = null) -> void:
	if not player_info.avatar_small == null:
		# TODO SET AVATAR PIC
		pass

#
# ---- INTERNALS
#

func _disconnect_player_info(player: PlayerInfo) -> void:
	if player != null:
		player.display_name_set.disconnect(_on_name_set)
		player.nickname_set.disconnect(_on_name_set)
		player.avatar_small_set.disconnect(_on_avatar_set)


func _connect_player_info(player: PlayerInfo) -> void:
	if player != null:
		player.display_name_set.connect(_on_name_set)
		player.nickname_set.connect(_on_name_set)
		_on_name_set()
		player.avatar_small_set.connect(_on_avatar_set)
		_on_avatar_set()
