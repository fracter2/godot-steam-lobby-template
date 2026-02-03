extends VBoxContainer

@onready var player_row_template: HBoxContainer = $PlayerRowTemplate

@onready var avatar_child_index: int = $PlayerRowTemplate/TextureAvatar.get_index()
@onready var display_name_child_index: int = $PlayerRowTemplate/LabelName.get_index()

func _ready() -> void:

	for p_id: int in Lobby.players:
		add_new_row(p_id)

	Lobby.player_info_set.connect(_on_player_info_set)
	Steam.avatar_loaded.connect(_on_avatar_loaded)
	#Steam.avatar_image_loaded



func _on_player_info_set(peer_id: int, param: String, value: Variant) -> void:
	if get_node_or_null(_id_to_node_name(peer_id)) == null:
		add_new_row(peer_id)

	match param:
		"name":
			_set_peer_display_name(peer_id, value)
		#"nickname"
		"steam_id":
			Steam.getSmallFriendAvatar(value)


func _on_avatar_loaded(avatar_id: int, size_: int, data: Array) -> void:
	breakpoint
	#var result: Dictionary = Steam.getImageRGBA()



func add_new_row(peer_id: int) -> void:
	if get_node_or_null(_id_to_node_name(peer_id)) != null:
		return

	var new_row: HBoxContainer = player_row_template.duplicate()
	new_row.visible = true
	new_row.name = _id_to_node_name(peer_id)
	add_child(new_row)

	if Lobby.has_player_info(peer_id, "name"):
		_set_peer_display_name(peer_id, Lobby.get_player_info(peer_id, "name", "DefaultName"))
	if Lobby.has_player_info(peer_id, "steam_id"):
		Steam.getSmallFriendAvatar(Lobby.get_player_info(peer_id, "steam_id", 0))


func _id_to_node_name(id: int) -> String:
	return "peer_%d" % id


func _set_peer_display_name(id: int, new_name: String) -> void:
	var node: HBoxContainer = get_node_or_null(_id_to_node_name(id))
	if node == null: return

	(node.get_child(display_name_child_index) as Label).text = new_name
