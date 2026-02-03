class_name SteamMultiplayerLobby
extends MultiplayerLobby

var init_as_host: bool
var init_id: int

## Steam lobby id assosiated with this lobby resource.
var lobby_id: int = 0
var owner_steam_id: int = 0

#
# ---- Procedure ----
#

func _init(lobby_id_: int, as_host: bool) -> void:								# TODO REVERSE ORDER OF ARGS and CLARIFY LOBBY ID DOESN'T MATTER IF HOSTING
	if not Steamworks.steam_enabled:
		print_debug("Cannot create SteamMultiplayerLobby when steam is not enabled and active!")
		return

	init_id = lobby_id_
	init_as_host = as_host

	Steam.lobby_created.connect(_on_lobby_created_wrapper)
	Steam.lobby_joined.connect(_on_lobby_joined_wrapper)						# NOTE Called when YOU enter either your own or other's lobbies... # TODO Does it call for other users too?
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
			if lobby_id != 0 and Steam.isLobby(lobby_id):
				Steam.leaveLobby(lobby_id)
		#NOTIFICATION_CRASH:												# TODO TEST IF THIS IS NEEDED


#
# ---- API ----
#

func is_in_lobby() -> bool: return lobby_id != 0

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

	elif Steam.isLobby(init_id):
		print("Attempting to join a lobby on steam! lobby id: %d" % init_id)
		Steam.joinLobby(init_id)
	else:
		push_warning("lobby_id %s could not be found or is not a lobby!" % init_id)
		return false

	return true

#
# ---- Signals ----
#

func _on_lobby_joined_wrapper(joined_lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	print("Recieved Steam lobby join response")
	if is_in_lobby():
		print_debug("Already in a lobby but still recieved join response. Ignoring")
		return

	var err: String = _on_lobby_joined(joined_lobby_id, _permissions, _locked, response)			# TODO Rename to... _setup_join_lobby_connection
	if err: disconnected.emit(err)

	connected_as_client.emit()
	var my_peer_id: int = multiplayer_peer.get_unique_id()
	Lobby.set_player_info(my_peer_id, "name", Steamworks.persona_name)
	Lobby.set_player_info(my_peer_id, "steam_id", Steamworks.steam_id)
	var owner_peer_id: int = (multiplayer_peer as SteamMultiplayerPeer).get_peer_id_for_steam_id(owner_steam_id)
	Lobby.set_player_info(owner_peer_id, "name", Steam.getFriendPersonaName(owner_steam_id))
	Lobby.set_player_info(owner_peer_id, "steam_id", owner_steam_id)


# NOTE Returns "" on success
func _on_lobby_joined(joined_lobby_id: int, _permissions: int, _locked: bool, response: int) -> String:			# TODO User Error as return type
	if is_in_lobby(): return "DIFFERENT LOBBY IS ALREADY SET UP! CANNOT JOIN 2 AT ONCE"
	if response != 1: return _get_fail_response_description(response)

	assert(joined_lobby_id == init_id, "As far as i understand, these values should be the same if init_id was used to find/create the lobby...")
	lobby_id = joined_lobby_id
	owner_steam_id = Steam.getLobbyOwner(lobby_id)
	if owner_steam_id == Steamworks.steam_id:
		return "joined lobby and became the owner right away... Dunno how to handle this so just break"

	_create_multiplayer_peer()
	#var error: Error = (multiplayer_peer as SteamMultiplayerPeer).create_client(owner_steam_id, 0)	# TEST
	var error: Error = (multiplayer_peer as SteamMultiplayerPeer).connect_to_lobby(lobby_id)		# TEST
	if error != OK:
		return "ERROR CREATING CLIENT\nCODE: " + str(error)

	return ""


func _on_lobby_created_wrapper(conn: int, created_lobby_id: int) -> void:
	print("Recieved Steam lobby created response")
	if is_in_lobby():
		print_debug("Already in a lobby but still recieved created response. Ignoring. I screwed up somewhow")
		breakpoint
		return
	var err: String = _on_lobby_created(conn, created_lobby_id)										# TODO Rename to... setup_created_lobby_connection
	if err: disconnected.emit(err)

	connected_as_host.emit()
	var my_peer_id: int = multiplayer_peer.get_unique_id()
	Lobby.set_player_info(my_peer_id, "name", Steamworks.persona_name)
	Lobby.set_player_info(my_peer_id, "steam_id", Steamworks.steam_id)


# NOTE Returns "" on success
func _on_lobby_created(conn: int, created_lobby_id: int) -> String:				# TODO User Error as return type
	if is_in_lobby(): return "LOBBY IS ALREADY SET UP!"							# TODO Remove redundant with earlier check
	if conn != 1: return 'ERROR CREATING STEAM LOBBY\nCODE: '+str(conn)

	lobby_id = created_lobby_id
	owner_steam_id = Steamworks.steam_id
	assert(Steamworks.steam_id == Steam.getLobbyOwner(created_lobby_id))

	_create_multiplayer_peer()
	#var error: Error = (multiplayer_peer as SteamMultiplayerPeer).create_host(0) 					# TEST		# this is virtual port not player limit do not change
	var error: Error = (multiplayer_peer as SteamMultiplayerPeer).host_with_lobby(created_lobby_id) # TEST
	if error != OK:
		return "ERROR CREATING HOST CLIENT\nCODE: " + str(error)

	var my_name: String = Util.limit_string_to_size(Steamworks.persona_name, 20)
	Steam.setLobbyData(lobby_id, "name", (my_name+"'s Lobby"))					# TODO Allow setting a lobby name
	Steam.setLobbyJoinable(lobby_id, true)
	Steam.allowP2PPacketRelay(true)												# TODO Remove, this should be redundant
	return ""


func _on_kicked() -> void:
	disconnected.emit("Got kicked")


func _on_peer_connected(peer_id: int) -> void:
	if Lobby.players.has(peer_id):
		print_debug("in SteamMultiplayerLobby._on_peer_connected(%d), somehow already have the peer_id in the players[] dict" % peer_id)
	else:
		Lobby.add_new_player_info(peer_id)

	var steam_id: int = (multiplayer_peer as SteamMultiplayerPeer).get_steam_id_for_peer_id(peer_id)
	Lobby.set_player_info(peer_id, "name", Steam.getFriendPersonaName(steam_id))
	Lobby.set_player_info(peer_id, "steam_id", steam_id)


func _on_peer_disconnected(peer_id: int) -> void:													# TODO REMOVE THIS IS JUST TO TEST WHAT TRIGGERS FIRST, multiplayer.peer_connected or this
	if Lobby.players.has(peer_id):
		Lobby.clear_player_info(peer_id)
	else:
		print_debug("in SteamMultiplayerLobby._on_peer_disconnected(%d), somehow dont have the peer_id in the players[] dict" % peer_id)


#
# ---- Internal logic ----
#

func _create_multiplayer_peer() -> void:
	var peer: SteamMultiplayerPeer = SteamMultiplayerPeer.new()
	peer.peer_connected.connect(_on_peer_connected)
	peer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer_peer = peer
	multiplayer_peer_set.emit(peer)


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
