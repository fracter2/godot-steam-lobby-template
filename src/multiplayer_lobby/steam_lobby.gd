class_name SteamMultiplayerLobby
extends MultiplayerLobby

var init_as_host: bool

#
# ---- Procedure ----
#

func _init(lobby_id_: int, as_host: bool) -> void:								# TODO REVERSE ORDER OF ARGS and CLARIFY LOBBY ID DOESN'T MATTER IF HOSTING
	if not Steamworks.steam_enabled:
		print_debug("Cannot create SteamMultiplayerLobby when steam is not enabled and active!")
		return

	lobby_id = lobby_id_
	init_as_host = as_host

	Steam.lobby_created.connect(_on_lobby_created_wrapper)
	Steam.lobby_joined.connect(_on_lobby_joined_wrapper)
	Steam.lobby_kicked.connect(_on_kicked)
	#Steam.lobby_chat_update
	#Steam.lobby_match_list
	#Steam.lobby_data_update
	#Steam.lobby_message														# TODO Setup messaging support... consider sepparate "Chat" autoload? connect to handler?

	#Steam.joinParty()
	#Steam.createBeacon() 	# Wasdis about??





# Cleanup
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PREDELETE:
			if multiplayer_peer and is_instance_valid(multiplayer_peer):
				multiplayer_peer.close()
			if lobby_id != 0:
				Steam.leaveLobby(lobby_id)
		#NOTIFICATION_CRASH:												# TODO TEST IF THIS IS NEEDED


#
# ---- API ----
#

func is_active() -> bool: return lobby_id != 0

## Returns Steam.getPersonaName()
func get_user_name() -> String: return Steam.getPersonaName()

## Returns Steam.getSteamID()
func get_user_id() -> int: return Steam.getSteamID()

func initiate_connection() -> bool:
	if !Steamworks.steam_enabled:
		push_warning("cannot join / host since Steam is not started or is disabled!")
		return false


	if init_as_host:
		print("Attempting to host a lobby on steam! lobby type: %d, max player count: %d" % [Steam.LOBBY_TYPE_FRIENDS_ONLY, 4])
		Steam.createLobby(Steam.LOBBY_TYPE_FRIENDS_ONLY, 4) # 4 player lobby					# TODO Clarify player limit and lobby type to a var

	elif Steam.isLobby(lobby_id):
		print("Attempting to join a lobby on steam! lobby id: %d" % lobby_id)
		Steam.joinLobby(lobby_id)
	else:
		push_warning("lobby_id %s could not be found or is not a lobby!" % lobby_id)
		return false

	return true

#
# ---- Signals ----
#

func _on_lobby_joined_wrapper(joined_lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	print("Recieved Steam lobby join response")
	var err: String = _on_lobby_joined(joined_lobby_id, _permissions, _locked, response)
	if err: disconnected.emit(err)
	else: connected_as_client.emit()


# NOTE Returns "" on success
func _on_lobby_joined(joined_lobby_id: int, _permissions: int, _locked: bool, response: int) -> String:	# TODO User Error as return type
	if is_active(): return "LOBBY IS ALREADY SET UP!"
	if response != 1: return _get_fail_response_description(response)

	lobby_id = joined_lobby_id
	owner_id = Steam.getLobbyOwner(lobby_id)
	if owner_id == Steamworks.steam_id:
		return "joined lobby and became the owner right away... Dunno how to handle this so just break"

	_create_multiplayer_peer()
	var error: Error = (multiplayer_peer as SteamMultiplayerPeer).create_client(owner_id, 0)
	if error != OK:
		return "ERROR CREATING CLIENT\nCODE: " + str(error)

	players[1] = {"name": Steam.getFriendPersonaName(owner_id), "id": owner_id}						# TODO Make player info struct
	players[multiplayer_peer.get_unique_id()] = {"name": Steamworks.persona_name, "id": Steamworks.steam_id}
	return ""


func _on_lobby_created_wrapper(conn: int, created_lobby_id: int) -> void:
	print("Recieved Steam lobby created response")
	var err: String = _on_lobby_created(conn, created_lobby_id)
	if err: disconnected.emit(err)
	else: connected_as_host.emit()


# NOTE Returns "" on success
func _on_lobby_created(conn: int, created_lobby_id: int) -> String:										# TODO DOESN'T QUIT PREVIOUS LOBBY... does it prevent mutliple lobbies? prob not... 	# TODO User Error as return type
	if is_active(): return "LOBBY IS ALREADY SET UP!"
	if conn != 1: return 'ERROR CREATING STEAM LOBBY\nCODE: '+str(conn)

	lobby_id = created_lobby_id
	owner_id = Steam.getSteamID()

	_create_multiplayer_peer()
	var error: Error = (multiplayer_peer as SteamMultiplayerPeer).create_host(0) # this is virtual port not player limit do not change
	if error != OK:
		return "ERROR CREATING HOST CLIENT\nCODE: " + str(error)

	var my_name: String = Util.limit_string_to_size(Steam.getPersonaName(), 20)
	Steam.setLobbyData(lobby_id, "name", (my_name+"'s Lobby"))					# TODO Allow setting a lobby name
	Steam.setLobbyJoinable(lobby_id, true)



	players[1] = {"name": my_name, "id": Steam.getSteamID()}
	Steam.allowP2PPacketRelay(true)												# TODO Remove, this should be redundant
	return ""


func _on_kicked() -> void:
	disconnected.emit("Got kicked")


func _on_peer_connected(peer_id: int) -> void:
	if players.has(peer_id):
		print_debug("in SteamMultiplayerLobby._on_peer_connected(%d), somehow already have the peer_id in the players[] dict" % peer_id)
		return
	var steam_id: int = (multiplayer_peer as SteamMultiplayerPeer).get_steam_id_for_peer_id(peer_id)
	players[peer_id] = {"name": Steam.getFriendPersonaName(steam_id), "id": steam_id}


func _on_peer_disconnected(peer_id: int) -> void:
	if not players.has(peer_id):
		print_debug("in SteamMultiplayerLobby._on_peer_disconnected(%d), somehow dont have the peer_id in the players[] dict" % peer_id)
		return
	players.erase(peer_id)

#
# ---- Internal logic ----
#

func _create_multiplayer_peer() -> void:
	var peer: SteamMultiplayerPeer = SteamMultiplayerPeer.new()
	peer.peer_connected.connect(_on_peer_connected)
	peer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer_peer = peer


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
