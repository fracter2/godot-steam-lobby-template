class_name NetworkLobby extends Node
																				# TODO Remove class name, this shouldn't really be it's own class thing, just autoload

# NOTE DEPENDS ON GODOTSTEAM plugin and launchcmd_parser.gd


var lobby_instance: MultiplayerLobbyAPI = null

signal critical_error(message:String)

## Successfully hosted or joined as client
signal connected																# TODO Consider renaming to "lobby_entered" or similar

## Disconnect as host / client, or failed connected attempt
signal disconnected(message:String)												# TODO Consider renaming to "lobby_exited" or similar

signal player_info_updated(peer_id: int, update_type: MultiplayerLobbyAPI.PLAYER_INFO_UPDATE, param: String, value: Variant)		# TODO ADD A WRAPPER HERE that calls this and changes the corresponding element

#
# ---- MAIN CALLBACKS ----
#
func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = -1														# TODO Consider global constants CONST autoload
	process_physics_priority = -1

func _ready() -> void:
	critical_error.connect(_on_critical_error)

	Steam.join_requested.connect(_on_lobby_join_requested)

	#Steam.lobby_invite 		# NOTE Allows automatic acceptance of invites. lol


	multiplayer.connected_to_server.connect(_on_connected_to_server)			# NOTE So this only calls locally once.
	multiplayer.connection_failed.connect(_on_connection_failed)
	#multiplayer.peer_connected													# TODO CLARIFY does this emit for EACH when joining late? or only when already connected?	# TODO Ideally use this to get most player info locally
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	_check_launch_commands()

#
# ---- API ----
#

func is_in_lobby() -> bool:
	return lobby_instance != null

## Returns the result of the initiation [b]attempt[/b]. [signal connected] and [signal disconnected]
## emit when the result is granted (imagine it like waiting for the host / setup to respond)
func initiate_lobby(lobby: MultiplayerLobbyAPI) -> bool:
	if is_in_lobby():
		return false

	lobby.connected_as_client.connect(_on_connected_as_client)
	lobby.connected_as_host.connect(_on_connected_as_host)
	lobby.disconnected.connect(_on_disconnected)
	lobby.player_info_changed.connect(_on_player_info_changed)

	if lobby.initiate_connection():
		lobby_instance = lobby
		return true

	else:
		lobby.connected_as_client.disconnect(_on_connected_as_client)
		lobby.connected_as_host.disconnect(_on_connected_as_host)
		lobby.disconnected.disconnect(_on_disconnected)
		lobby.player_info_changed.disconnect(_on_player_info_changed)
		return false


func leave_lobby(message: String) -> void:
	if not is_in_lobby():
		print_debug("Tried to quit lobby when not in a lobby")
		return

	lobby_instance.free() 														# NOTE This will handle all the cleanup internally
	lobby_instance = null
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	disconnected.emit(message)


@rpc("any_peer", "reliable")													# TODO Delegatate to multiplayer lobby instance
func sync_info(name_: String, id: int) -> void:									# TODO NOTE This is meant to JUST send the info of all players TO THE REMOTE_SENDER. consider renaming
	var peer_id: int = multiplayer.get_remote_sender_id()
	if lobby_instance.players.has(peer_id):
		push_warning("attemped to sync_info() already existing peer")
		return

	lobby_instance.players[peer_id] = {"name": name_, "id": id}

	# TODO Send user data to
	var minimum_data: Dictionary = {}
	for p: Dictionary in lobby_instance.players:
		minimum_data[p] = {"name": lobby_instance.players[p]["name"], "id": lobby_instance.players[p]["id"]}		# TODO Why is this here?? should it not just send the player dict?
	_receive_player_data.rpc(minimum_data, peer_id)
	#player_info_updated.emit()

#
# ---- LOCAL UTIL ----
#

@rpc("reliable")
func _receive_player_data(data : Dictionary, _id:int) -> void:					# TODO Delegatate to multiplayer lobby instance
	lobby_instance.players = data
	#players_changed.emit()


static func _limit_string_to_size(txt: String, size: int) -> String:			# TODO Move to some utility file
	assert(size > 3)
	if txt.length() > size:														# TODO Clarify max name length const
		txt = txt.substr(0, size-3) + '...'
	return txt


func _check_launch_commands() -> void:
	if LaunchArgs.has_command("+connect_lobby"):
		var lobby_id_str: String = LaunchArgs.get_values("+connect_lobby")[0]	# Should only have one value anyway
		if not lobby_id_str.is_valid_int():
			push_error("Attempted to join lobby via launch argument '+connect_lobby with' with invalid lobby id: " + lobby_id_str)
			return

		print("Attempting to join lobby right on start. Lobby id: " + lobby_id_str)
		var lobby: SteamMultiplayerLobby = SteamMultiplayerLobby.new(int(lobby_id_str), false)
		if not initiate_lobby(lobby):
			print("Attempt to join lobby got cancelled (figure out why yourself)")

#
# ---- SIGNAL CALLBACKS ----
#
func _on_critical_error(message: String) -> void:
	push_error("LEAVING LOBBY - CRITICAL NETWORK_LOBBY ERROR: " + message)
	leave_lobby(message)


func _on_lobby_join_requested(this_lobby_id: int, _friend_id: int) -> void:
	Steam.joinLobby(int(this_lobby_id))


# TODO Connect to connected signal, or similar.
func _on_connected_to_server() -> void:
	var peer_id: int = multiplayer.get_unique_id()
	var my_name : String = _limit_string_to_size(lobby_instance.get_user_name(), 20)
	var my_user_id: int = lobby_instance.get_user_id()

	lobby_instance.players[peer_id] = {"name": my_name, "id": my_user_id}		# TODO Optimize sync_ifo logic to only send new data. Bandwidth aint free... # TODO Delegatate to multiplayer lobby instance
	sync_info.rpc(my_name, my_user_id)


# TODO Connect to disconnected signal, or similar.
func _on_peer_disconnected(id: int) -> void:									# TODO Delegatate to multiplayer lobby instance
	if id == 1:
		leave_lobby("Host left lobby")			# TODO This should be handled by the lobby!!
	else:
		lobby_instance.players.erase(id)
		player_info_updated.emit(id, MultiplayerLobbyAPI.PLAYER_INFO_UPDATE.PLAYER_REMOVED, "")


# TODO Connect to disconnected signal, or similar.
func _on_connection_failed() -> void:											# TODO Delegatate to multiplayer lobby instance
	multiplayer.multiplayer_peer.close()
	critical_error.emit('FAILED TO CONNECT...')


func _on_connected_as_client() -> void:
	connected.emit()


func _on_connected_as_host() -> void:
	connected.emit()

func _on_disconnected() -> void:
	disconnected.emit()

func _on_player_info_changed(peer_id: int, update_type: MultiplayerLobbyAPI.PLAYER_INFO_UPDATE, param: String, value: Variant) -> void:
	player_info_updated.emit(peer_id, update_type, param, value)


#
# ----
#
