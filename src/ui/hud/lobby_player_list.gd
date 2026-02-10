extends VBoxContainer

@onready var player_row_template: HBoxContainer = $PlayerRowTemplate
@onready var avatar_child_index: int = $PlayerRowTemplate/TextureAvatar.get_index()
@onready var display_name_child_index: int = $PlayerRowTemplate/LabelName.get_index()

var player_rows: Dictionary[int, HBoxContainer]		# NOTE Use peer_id for key


#
# ---- PROCEDURE ----
#

func _ready() -> void:

	for player: PlayerInfo in Lobby.players.values():
		_load_avatar_and_name(player)
		add_new_row(player)

	Lobby.player_added.connect(add_new_row)
	Lobby.player_removed.connect(remove_row)
	Lobby.player_name_set.connect(_on_player_name_set)
	Lobby.player_nickname_set.connect(_on_player_name_set)
	Lobby.player_medium_avatar_set.connect(_set_peer_avatar)

	Lobby.player_steam_id_set.connect(_on_player_steam_id_set)
	Steam.avatar_loaded.connect(_on_avatar_loaded)


#
# ---- SIGNAL CALBACKS
#

func _on_player_name_set(_display_name: StringName, player: PlayerInfo) -> void:
	_set_peer_display_name(player)


func _on_player_steam_id_set(_steam_id: int, player: PlayerInfo) -> void:
	_load_avatar_and_name(player)


func _on_avatar_loaded(user_id: int, avatar_size: int, avatar_buffer: PackedByteArray) -> void:
	var avatar_image: Image = Image.create_from_data(avatar_size, avatar_size, false, Image.FORMAT_RGBA8, avatar_buffer)

	for p_info: PlayerInfo in Lobby.players.values():
		if not p_info.steam_id == user_id: continue

		if avatar_size <= 32: 		p_info.avatar_small = avatar_image
		elif avatar_size <= 64: 	p_info.avatar_medium = avatar_image
		elif avatar_size <= 128: 	p_info.avatar_large = avatar_image
		else:
			var large_avatar: Image = avatar_image.duplicate()
			large_avatar.resize(128, 128, Image.INTERPOLATE_LANCZOS)
			p_info.avatar_large = large_avatar
			# TODO ADD SUPER LARGE AVATAR into PlayerInfo

		break



#
# ---- INTERNALS
#

func _load_avatar_and_name(player: PlayerInfo) -> void:
	if player.steam_id == 0: return

	if player.display_name.is_empty():
		var naem: String = Steam.getFriendPersonaName(player.steam_id)
		if not (naem.is_empty() or naem == null): player.display_name = naem

	if player.nickname.is_empty():
		var nick:String = Steam.getPlayerNickname(player.steam_id)
		if nick != null: player.nickname = nick

	if player.avatar_medium == null:
		Steam.getPlayerAvatar(Steam.AVATAR_MEDIUM, player.steam_id)


func add_new_row(player: PlayerInfo) -> void:
	if player_rows.has(player.peer_id):
		return

	var new_row: HBoxContainer = player_row_template.duplicate()
	new_row.visible = true
	new_row.name = _id_to_node_name(player.peer_id)
	add_child(new_row)
	player_rows.set(player.peer_id, new_row)

	_set_peer_display_name(player)


func remove_row(player:PlayerInfo) -> void:
	if player_rows.has(player.peer_id):
		player_rows[player.peer_id].queue_free()
		player_rows.erase(player.peer_id)


func _id_to_node_name(id: int) -> String:
	return "peer_%d" % id


func _set_peer_display_name(player: PlayerInfo) -> void:
	if not player_rows.has(player.peer_id):										# TODO CONSIDER REMOVING, should be redundant with lobby.player_added sigakl
		add_new_row(player)

	var new_name: String = "DefaultName"
	if not player.nickname.is_empty(): new_name =  player.nickname
	elif not player.display_name.is_empty(): new_name =  player.display_name

	var node: HBoxContainer = player_rows.get(player.peer_id)
	(node.get_child(display_name_child_index) as Label).text = new_name


func _set_peer_avatar(avatar:Image, player: PlayerInfo) -> void:
	if not player_rows.has(player.peer_id):										# TODO CONSIDER REMOVING, should be redundant with lobby.player_added sigakl
		add_new_row(player)

	var textr: Texture2D = null
	if player.avatar_medium != null: textr = ImageTexture.create_from_image(player.avatar_medium)
	elif player.avatar_large != null: textr = ImageTexture.create_from_image(player.avatar_large)
	else: return

	var node: HBoxContainer = player_rows.get(player.peer_id)
	(node.get_child(avatar_child_index) as TextureRect).texture = textr
