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
		if player_info != null:
			player_info.display_name_set.disconnect(_update_name)
			player_info.nickname_set.disconnect(_update_name)
		player_info = info
		if info != null:
			info.display_name_set.connect(_update_name)
			info.nickname_set.connect(_update_name)
			_update_name()
	#get():	# NOTE This should still be proovided by default
	#	return player_info



func _enter_tree() -> void:
	if Lobby.players.has(peer_id):
		#player_info = Lobby.players.get(peer_id)
		_update_name()
	else:
		push_error("PlayerEntity at %s \n -> peer_id %d set but player_info not found!" % [get_path(), peer_id])

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if multiplayer.get_unique_id() == peer_id:
		camera_2d.enabled = true
		camera_2d.make_current()


func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority(): return

	position = local_client_syncronizer.position


func _update_name() -> void:
	if player_info == null: return

	if not player_info.nickname.is_empty(): 		name_label.text = player_info.nickname
	elif not player_info.display_name.is_empty():	name_label.text = player_info.display_name
	else: 											name_label.text = "DefaultName"
