class_name PlayerEntity
extends Node2D


@export var peer_id: int = 1:
	set(id):
		peer_id = id
		local_client_syncronizer.set_multiplayer_authority(id)
		player_info = Lobby.players.get(id)

@export var speed: float = 100

@onready var camera_2d: Camera2D = $Camera2D
@export var name_label: Label

#@onready var local_client_syncronizer: LocalClientSyncronizer = $LocalClientSyncronizer
@export var local_client_syncronizer: LocalClientSyncronizer

var player_info: PlayerInfo = null:
	set(info):
		_disconnect_player_info(player_info)
		player_info = info
		_connect_player_info(info)

	#get():	# NOTE This should still be proovided by default
	#	return player_info



#
# ---- PROCEDURE ----
#

func _enter_tree() -> void:
	if player_info == null:
		push_warning("Player entity at %s is missing player_info on _enter_tree()!")

	if not Lobby.players.has(peer_id):
		push_error("PlayerEntity at %s \n -> peer_id %d set but player_info not found!" % [get_path(), peer_id])


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if multiplayer.get_unique_id() == peer_id:
		camera_2d.enabled = true
		camera_2d.make_current()


func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority(): return

	position = local_client_syncronizer.position


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
		player.avatar_small_set.connect(_on_avatar_set)
		_on_name_set()
		_on_avatar_set()
