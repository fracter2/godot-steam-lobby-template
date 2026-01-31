class_name Player
extends Node2D


@export var peer_id:int = 1:													# TODO REMOVE, redundant if the authority is also set, since you can just use get_multiplayer_authority()
	set(id):
		peer_id = id
		set_multiplayer_authority(id)
		_check_if_local_authority()
	get():
		return peer_id

@export var speed: float = 120

@onready var name_label: Label = $NameLabel


func _ready() -> void:
	Lobby.player_info_updated.connect(_check_if_name_changed)



func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority(): return

	var input_dir: Vector2 = Vector2(Input.get_axis(&"ui_left", &"ui_right"),  Input.get_axis(&"ui_up", &"ui_down"))
	position += input_dir * speed * delta


func _check_if_name_changed(peer_id_: int, update_type: MultiplayerLobbyAPI.PLAYER_INFO_UPDATE, param: String, value: Variant) -> void:
	if (get_multiplayer_authority() == peer_id_
	and update_type == MultiplayerLobbyAPI.PLAYER_INFO_UPDATE.PROPERTY_CHANGED
	and param == "name"):
		name_label.text = value


func _check_if_local_authority() -> void:
	if peer_id == multiplayer.get_unique_id():
		var cam_node: Camera2D = Camera2D.new()
		cam_node.name = "Local Camera"
		cam_node.enabled = true
		add_child(cam_node, true)
