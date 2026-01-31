class_name Player
extends Node2D


@export var peer_id:int = 1:													# TODO REMOVE, redundant if the authority is also set, since you can just use get_multiplayer_authority()
	set(id):
		peer_id = id
		set_multiplayer_authority(id)
	get():
		return peer_id

@export var speed: float = 120

@onready var name_label: Label = $NameLabel


func _ready() -> void:
	Lobby.player_info_updated.connect(_check_if_name_changed)
	name_label.text = Lobby.get_player_info(peer_id, "name", "DefaultName")

	if is_multiplayer_authority():
		_spawn_local_camera()


func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority(): return

	var input_dir: Vector2 = Vector2(Input.get_axis(&"move_left", &"move_right"),  Input.get_axis(&"move_up", &"move_down"))
	position += input_dir * speed * delta


func _check_if_name_changed(peer_id_: int, update_type: MultiplayerLobbyAPI.PLAYER_INFO_UPDATE, param: String, value: Variant) -> void:
	if (get_multiplayer_authority() == peer_id_
	and update_type == MultiplayerLobbyAPI.PLAYER_INFO_UPDATE.PROPERTY_CHANGED
	and param == "name"):
		name_label.text = value


func _spawn_local_camera() -> void:
	var cam_node: Camera2D = Camera2D.new()
	cam_node.name = "Local Camera"
	cam_node.enabled = true
	add_child(cam_node, true)
