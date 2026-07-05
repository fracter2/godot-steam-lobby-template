class_name SteamMultiplayerLobby
extends MultiplayerLobby

var init_as_host: bool
var init_id: int
var lobby_type: Steam.LobbyType
var player_max: int:
	set(val):
		player_max = clampi(val, 2, 250)

## Steam lobby id assosiated with this lobby resource.
var lobby_id: int = 0
var owner_steam_id: int = 0


#
# ---- Procedure ----
#

## Note lobby_id is just for joining other lobbies, and is ignored when hosting.
func _init(lobby_id_: int, as_host: bool, player_max_: int = 124, lobby_type_: Steam.LobbyType = Steam.LobbyType.LOBBY_TYPE_FRIENDS_ONLY) -> void:
	if not Steamworks.steam_enabled:
		print_debug("Cannot create SteamMultiplayerLobby when steam is not enabled and active!")
		return

	init_id = lobby_id_
	init_as_host = as_host
	player_max = player_max_
	lobby_type = lobby_type_

	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)						# NOTE Called when YOU enter either your own or other's lobbies...
	Steam.lobby_kicked.connect(_on_kicked)


# Cleanup
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PREDELETE:
			if multiplayer_peer and is_instance_valid(multiplayer_peer):
				multiplayer_peer.close()
			if lobby_id != 0 and Steam.isLobby(lobby_id):
				Steam.leaveLobby(lobby_id)


#
# ---- API ----
#

func is_in_lobby() -> bool: return lobby_id != 0


## Returns Steam.getPersonaName()
func get_user_name() -> String: return Steam.getPersonaName()


func is_lobby_owner() -> bool:
	return owner_steam_id == Steamworks.steam_id


func initiate_connection() -> bool:
	if !Steamworks.steam_enabled:
		push_warning("cannot join / host since Steam is not started or is disabled!")
		return false

	if init_as_host:
		Log.pprint("Attempting to host a lobby on steam! lobby type: %d, max player count: %d" % [lobby_type, player_max])
		Steam.createLobby(lobby_type, player_max)

	elif Steam.isLobby(init_id):
		Log.pprint("Attempting to join a lobby on steam! lobby id: %d" % init_id)
		Steam.joinLobby(init_id)
	else:
		push_warning("lobby_id %s could not be found or is not a lobby!" % init_id)
		return false

	return true


#
# ---- Signals ----
#

func _on_lobby_joined(joined_lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	Log.pprint("Recieved Steam lobby join response")
	var err: String = _setup_lobby_join_connection(joined_lobby_id, _permissions, _locked, response)
	if err:
		disconnected.emit(err)
	else:
		connected_as_client.emit()												# TODO CONSIDER DIRECTLY CALLING THE CORRESPONDING Lobby FUNC TO CLARIFY DEPENDANCY
		_fill_own_player_info()


func _on_lobby_created(conn: int, created_lobby_id: int) -> void:
	Log.pprint("Recieved Steam lobby created response")
	var err: String = _setup_lobby_host_connection(conn, created_lobby_id)
	if err:
		disconnected.emit(err)
	else:
		connected_as_host.emit()												# TODO CONSIDER DIRECTLY CALLING THE CORRESPONDING Lobby FUNC TO CLARIFY DEPENDANCY
		_fill_own_player_info()


func _on_kicked(_from_lobby_id: int, _by_admin_id: int, _reason: int) -> void:
	disconnected.emit("Got kicked")


func _on_peer_connected(peer_id: int) -> void:
	if not Lobby.players.has(peer_id):
		Lobby.add_new_player_info(peer_id)

	var peer_info: PlayerInfo = Lobby.players.get(peer_id)
	peer_info.steam_id = (multiplayer_peer as SteamMultiplayerPeer).get_steam_id_for_peer_id(peer_id)
	peer_info.display_name = Steam.getFriendPersonaName(peer_info.steam_id)


func _on_peer_disconnected(peer_id: int) -> void:								# TODO REMOVE, PREFER LOBBY MANAGER HANDLING THIS
	if Lobby.players.has(peer_id):
		Lobby.clear_player_info(peer_id)


#
# ---- Internal logic ----
#

## NOTE Returns "" on success
func _setup_lobby_join_connection(joined_lobby_id: int, _permissions: int, _locked: bool, response: int) -> String:
	if is_in_lobby(): return "DIFFERENT LOBBY IS ALREADY SET UP! CANNOT JOIN 2 AT ONCE"
	if response != 1: return _get_fail_response_description(response)

	assert(joined_lobby_id == init_id, "As far as i understand, these values should be the same if init_id was used to find/create the lobby...")
	lobby_id = joined_lobby_id
	owner_steam_id = Steam.getLobbyOwner(lobby_id)
	if owner_steam_id == Steamworks.steam_id:
		return "joined lobby and became the owner right away... Dunno how to handle this so just break"

	_create_multiplayer_peer()
	var error: Error = (multiplayer_peer as SteamMultiplayerPeer).connect_to_lobby(lobby_id)
	if error != OK:
		return "ERROR CREATING CLIENT\nCODE: " + str(error)

	return ""


## NOTE Returns "" on success
func _setup_lobby_host_connection(conn: int, created_lobby_id: int) -> String:
	if is_in_lobby(): return "LOBBY IS ALREADY SET UP!"
	if conn != 1: return 'ERROR CREATING STEAM LOBBY\nCODE: '+str(conn)

	lobby_id = created_lobby_id
	owner_steam_id = Steamworks.steam_id
	assert(Steamworks.steam_id == Steam.getLobbyOwner(created_lobby_id))

	_create_multiplayer_peer()
	var error: Error = (multiplayer_peer as SteamMultiplayerPeer).host_with_lobby(created_lobby_id) # TEST
	if error != OK:
		return "ERROR CREATING HOST CLIENT\nCODE: " + str(error)

	var my_name: String = limit_string_to_size(Steamworks.persona_name, 20)
	Steam.setLobbyData(lobby_id, "name", (my_name+"'s Lobby"))					# TODO Allow setting a lobby name
	Steam.setLobbyJoinable(lobby_id, true)
	Steam.allowP2PPacketRelay(true)												# TODO Remove, this should be redundant
	return ""


func _create_multiplayer_peer() -> void:
	var peer: SteamMultiplayerPeer = SteamMultiplayerPeer.new()
	peer.peer_connected.connect(_on_peer_connected)
	peer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer_peer = peer


func _fill_own_player_info() -> void:
	assert(Lobby.players.has(multiplayer_peer.get_unique_id()), "Users player info resource should have been created by now!")
	var my_p_info: PlayerInfo = Lobby.players.get(multiplayer_peer.get_unique_id())
	my_p_info.display_name = Steamworks.persona_name
	my_p_info.steam_id = Steamworks.steam_id


func _get_fail_response_description(response: int) -> String:
	match response:
		1:  return "OK."														# TODO Make use of the corresponding Steam. enum
		2:  return "This lobby no longer exists."
		3:  return "You don't have permission to join this lobby."
		4:  return "The lobby is now full."
		5:  return "Something unexpected happened!"
		6:  return "You are banned from this lobby."
		7:  return "You cannot join due to having a limited account."
		8:  return "This lobby is locked or disabled."
		9:  return "This lobby is community locked."
		10: return "A user in the lobby has blocked you from joining."
		11: return "A user you have blocked is in the lobby."

	return "Uknown responde id: " + str(response)


#
# ---- Generic Util ----
#

func limit_string_to_size(txt: String, size: int) -> String:
	assert(size > 0)
	if txt.length() > size:
		if size-3 > 0:
			txt = txt.substr(0, size-3) + '...'
		else:
			txt = txt.substr(0, size)
	return txt
