class_name NetworkLobby extends Node
																				# TODO Remove class name, this shouldn't really be it's own class thing, just autoload

# NOTE DEPENDS ON GODOTSTEAM plugin and launchcmd_parser.gd


var lobby_instance: MultiplayerLobbyAPI = null

signal critical_error(message:String)

## Successfully hosted or joined as client
signal connected

## Disconnect as host / client, or failed connected attempt
signal disconnected(message:String)

signal player_info_updated(peer_id: int, update_type: MultiplayerLobbyAPI.PLAYER_INFO_UPDATE, param: String)

#
# ---- MAIN CALLBACKS ----
#
func _init():
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = -1														# TODO Consider global constants CONST autoload
	process_physics_priority = -1

func _ready():
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

## Returns the result of the initiation [b]attempt[/b]. [signal connected] and [signal disconnected]
## emit when the result is granted (imagine it like waiting for the host / setup to respond)
func initiate_lobby(lobby: MultiplayerLobbyAPI) -> bool:
	if lobby_instance != null:
		return false
	var result: bool = lobby.initiate_connection()
	return result


func leave_lobby(message: String) -> void:
	if lobby_instance != null:
		lobby_instance.free()													# NOTE This will handle all the cleanup internally
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()					# TODO This prob not needed. Reconsider
	disconnected.emit(message)
	# TODO GO TO MAIN MENU


@rpc("any_peer", "reliable")													# TODO Delegatate to multiplayer lobby instance
func sync_info(name_: String, id: int) -> void:									# TODO NOTE This is meant to JUST send the info of all players TO THE REMOTE_SENDER. consider renaming
	var peer_id = multiplayer.get_remote_sender_id()
	if lobby_instance.players.has(peer_id):
		push_warning("attemped to sync_info() already existing peer")
		return

	lobby_instance.players[peer_id] = {"name": name_, "id": id}

	# TODO Send user data to
	var minimum_data = {}
	for p in lobby_instance.players:
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
func _on_critical_error(message: String):
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



#
# ----
#
