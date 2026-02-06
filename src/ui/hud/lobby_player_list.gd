extends VBoxContainer

@onready var player_row_template: HBoxContainer = $PlayerRowTemplate

@onready var avatar_child_index: int = $PlayerRowTemplate/TextureAvatar.get_index()
@onready var display_name_child_index: int = $PlayerRowTemplate/LabelName.get_index()

var player_rows: Dictionary[int, HBoxContainer]

func _ready() -> void:

	for player: PlayerInfo in Lobby.players.values():
		_get_player_avatar_and_name(player)
		add_new_row(player)

	Lobby.player_steam_id_set.connect(_on_player_steam_id_set)
	Lobby.player_name_set.connect(_on_player_name_set)
	Lobby.player_nickname_set.connect(_on_player_name_set)

	Steam.avatar_loaded.connect(_on_avatar_loaded)
	#Steam.avatar_image_loaded



func _on_player_steam_id_set(_steam_id: int, player: PlayerInfo) -> void:
	_get_player_avatar_and_name(player)


func _get_player_avatar_and_name(player: PlayerInfo) -> void:
	if player.steam_id == 0: return

	if player.display_name.is_empty():
		var naem: String = Steam.getFriendPersonaName(player.steam_id)
		if not (naem.is_empty() or naem == null): player.display_name = naem

	if player.nickname.is_empty():
		var nick:String = Steam.getPlayerNickname(player.steam_id)
		if nick != null: player.nickname = nick

	if player.avatar_small == null:
		Steam.getSmallFriendAvatar(player.steam_id)


func _on_player_name_set(_display_name: StringName, player: PlayerInfo) -> void:
	_set_peer_display_name(player)


func _on_avatar_loaded(_avatar_id: int, _size: int, _data: Array) -> void:
	breakpoint
	#var result: Dictionary = Steam.getImageRGBA()


func add_new_row(player: PlayerInfo) -> void:
	if player_rows.has(player.peer_id):
		return

	var new_row: HBoxContainer = player_row_template.duplicate()
	new_row.visible = true
	new_row.name = _id_to_node_name(player.peer_id)
	add_child(new_row)
	player_rows.set(player.peer_id, new_row)

	_set_peer_display_name(player)


func _id_to_node_name(id: int) -> String:
	return "peer_%d" % id


func _set_peer_display_name(p_info: PlayerInfo) -> void:
	if not player_rows.has(p_info.peer_id): return

	var new_name: String = "DefaultName"
	if not p_info.nickname.is_empty(): new_name =  p_info.nickname
	elif not p_info.display_name.is_empty(): new_name =  p_info.display_name

	var node: HBoxContainer = player_rows.get(p_info.peer_id)
	(node.get_child(display_name_child_index) as Label).text = new_name
