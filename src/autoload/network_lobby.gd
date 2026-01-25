class_name NetworkLobby extends Node
																				# TODO Remove class name, this shouldn't really be it's own class thing, just autoload

# NOTE DEPENDS ON GODOTSTEAM plugin and launchcmd_parser.gd


var lobby_instance: NetworkLobbyHandler = null

signal players_changed
signal critical_error(message:String)

## Successfully hosted or joined as client
signal connected

## Disconnect as host / client, or failed connected attempt
signal disconnected(message:String)


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
	#Steam.lobby_kicked
	#Steam.lobby_chat_update
	#Steam.lobby_match_list
	#Steam.lobby_data_update
	#Steam.lobby_message														# TODO Setup messaging support... consider sepparate "Chat" autoload? connect to handler?

	#Steam.joinParty()
	#Steam.createBeacon() 	# Wasdis about??

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
func initiate_lobby(lobby: NetworkLobbyHandler) -> bool:
	if lobby_instance != null:
		return false
	var result: bool = lobby.initiate_connection()
	return result


func leave_lobby(message: String) -> void:
	if lobby_instance != null:
		lobby_instance.free()														# NOTE This will handle all the cleanup internally
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()					# TODO This prob not needed. Reconsider
	disconnected.emit(message)
	# TODO GO TO MAIN MENU


@rpc("any_peer", "reliable")
func sync_info(name_: String, id: int) -> void:														# TODO NOTE This is meant to JUST send the info of all players TO THE REMOTE_SENDER. consider renaming
	var peer_id = multiplayer.get_remote_sender_id()
	if lobby_instance.players.has(peer_id):
		push_warning("attemped to sync_info() already existing peer")
		return

	lobby_instance.players[peer_id] = {"name": name_, "id": id}

	# TODO Send user data to
	var minimum_data = {}
	for p in lobby_instance.players:
		minimum_data[p] = {"name": lobby_instance.players[p]["name"], "id": lobby_instance.players[p]["id"]}						# TODO Why is this here?? should it not just send the player dict?
	_receive_player_data.rpc(minimum_data, peer_id)
	players_changed.emit()

#
# ---- LOCAL UTIL ----
#

@rpc("reliable")
func _receive_player_data(data : Dictionary, _id:int) -> void:
	lobby_instance.players = data
	players_changed.emit()

# TODO Move to dedicated util file or where it is used
static func _get_fail_response_description(response: int) -> String:
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
		var lobby: SteamNetworkLobbyHandler = SteamNetworkLobbyHandler.new(int(lobby_id_str), false)
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

	lobby_instance.players[peer_id] = {"name": my_name, "id": my_user_id}		# TODO Optimize sync_ifo logic to only send new data. Bandwidth aint free...
	sync_info.rpc(my_name, my_user_id)


# TODO Connect to disconnected signal, or similar.
func _on_peer_disconnected(id: int) -> void:
	if id == 1:																	# TODO Clarify that this is the server(?)
		leave_lobby("Host left lobby")											# TODO Make a lobby getter that checks if it should quit on host quit?
	else:
		lobby_instance.players.erase(id)
		players_changed.emit()


# TODO Connect to disconnected signal, or similar.
func _on_connection_failed() -> void:
	multiplayer.multiplayer_peer.close()
	critical_error.emit('FAILED TO CONNECT...')



#
# ----
#
@abstract
class NetworkLobbyHandler extends RefCounted:									# TODO Move to dedicated file. TODO Rename MultiplayerLobbyAPI
	# Lobby id. May be the same as Owner ID, like with EnetMultiplayerLobby
	var id: int = 0	# TODO Rename to lobby_id for extra clarity

	# Owner user id. This is not nessessarily the peer_id from multiplayer.get_unique_id().
	# With steam it is the account id.
	var owner_id: int = 0														# TODO Consider removing this...? since Steam.getLobbyOwner() and peer_id 1 is always the owner / host
																				# Could be a getter func instead, since a third party account system might have their own account id's
	# Player info dictionary.
	var players : Dictionary = {}

	# The mutliplayer peer used in the connection. This can be used as the multiplayer_peer for
	# any scene, like the actual game scene.
	# This is the same as Lobby.multiplayer.multiplayer_peer, set by the various join funcs.
	var multiplayer_peer: MultiplayerPeer

	# API to get the local users name. With SteamMultiplayerLobby it is the account name.
	@abstract func get_user_name() -> String

	# Gets the local users user_id. This may be different from the peer_id, wich you get from
	# multiplayer.get_unique_id() or multiplayer.get_peers()
	@abstract func get_user_id() -> int

	@abstract func initiate_connection() -> bool

	## Successfully hosted or joined as client
	signal connected_as_client
	signal connected_as_host

	## Disconnect as host / client, or failed connected attempt
	signal disconnected(message:String)


class EnetNetworkLobbyHandler extends NetworkLobbyHandler:						# TODO Rename EnetMultiplayerLobby
	var username: String = "DefaultName"
	var init_as_host:bool
	var init_ip: String
	var init_port: int

	func _init(is_host: bool = false, ip: String = "127.0.0.1", port: int = 8080, username_: String = "DefaultName") -> void:
		init_as_host = is_host
		username = username_
		init_ip = ip
		init_port = port

	func is_active() -> bool: return id != 0
	func get_user_name() -> String: return username								# NOTE if there is a (non-steam) account system, this would be the account name
	func get_user_id() -> int: return multiplayer_peer.get_unique_id()			# NOTE if there is a (non-steam) account system, this would be the account id

	func initiate_connection() -> bool:
		var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
		if init_as_host:
			return false
		else:
			# TODO Validate port and ip
			var error: Error = peer.create_client(init_ip, init_port)
			if error != Error.OK:
				push_warning("error while trying to EnetMultiplayerPeer.create_client(), error: " + str(error))
				return false
			else:
				_delegate_join_lobby.call_deferred()
				connected_as_client.emit()
				return true

	func _delegate_join_lobby() -> void:
		connected_as_client.emit()

	func _delegate_host_lobby() -> void:
		connected_as_host.emit()

	func _delegate_on_disconnected(message: String) -> void:
		disconnected.emit(message)


class SteamNetworkLobbyHandler extends NetworkLobbyHandler:						# TODO Rename SteamMultiplayerLobby
	var init_as_host: bool
	var lobby_id: int = 0

	func is_active() -> bool: return id != 0
	func get_user_name() -> String: return Steam.getPersonaName()
	func get_user_id() -> int: return Steam.getSteamID()

	func _init(lobby_id_: int, as_host: bool) -> void:
		lobby_id = lobby_id_
		init_as_host = as_host
		if not Steamworks.steam_enabled: return
		Steam.lobby_created.connect(_on_lobby_created_wrapper)
		Steam.lobby_joined.connect(_on_lobby_joined_wrapper)


	func initiate_connection() -> bool:
		if !Steamworks.steam_enabled:
			push_warning("cannot join / host since Steam is not started or is disabled!")
			return false

		if not Steam.isLobby(lobby_id):
			push_warning("lobby_id %s could not be found or is not a lobby!" % lobby_id)
			return false

		if init_as_host:
			print("Attempting to host a lobby on steam! lobby type: %i, max player count: %i" % [Steam.LOBBY_TYPE_FRIENDS_ONLY, 4])
			Steam.createLobby(Steam.LOBBY_TYPE_FRIENDS_ONLY, 4) # 4 player lobby					# TODO Clarify player limit and lobby type to a var
		else:
			print("Attempting to join a lobby on steam! lobby id: %i" % lobby_id)
			Steam.joinLobby(lobby_id)

		return true


	func _on_lobby_joined_wrapper(lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
		var err: String = _on_lobby_joined(lobby_id, _permissions, _locked, response)
		if err: disconnected.emit(err)
		else: connected_as_client.emit()


	# NOTE Returns "" on success
	func _on_lobby_joined(lobby_id: int, _permissions: int, _locked: bool, response: int) -> String:	# TODO User Error as return type
		if is_active(): return "LOBBY IS ALREADY SET UP!"
		if response != 1: return NetworkLobby._get_fail_response_description(response)

		# TODO IF SteamMultiplayerPeer DOESN'T NEED THIS, MOVE THIS BELOW
		id = lobby_id
		owner_id = Steam.getLobbyOwner(id)
		if owner_id == Steam.getSteamID():
			return "joined lobby and became the owner right away... Dunno how to handle this so just break"

		var peer = SteamMultiplayerPeer.new()
		var error = peer.create_client(owner_id, 0)
		if error != OK:
			return "ERROR CREATING CLIENT\nCODE: " + str(error)

		multiplayer_peer = peer
		players[1] = {"name": Steam.getFriendPersonaName(owner_id), "id": owner_id}					# TODO Make player info struct
		return ""


	func _on_lobby_created_wrapper(conn: int, lobby_id: int) -> void:
		var err: String = _on_lobby_created(conn, lobby_id)
		if err: disconnected.emit(err)
		else: connected_as_host.emit()


	# NOTE Returns "" on success
	func _on_lobby_created(conn: int, lobby_id: int) -> String:										# TODO DOESN'T QUIT PREVIOUS LOBBY... does it prevent mutliple lobbies? prob not... 	# TODO User Error as return type
		if is_active(): return "LOBBY IS ALREADY SET UP!"
		if conn != 1: return 'ERROR CREATING STEAM LOBBY\nCODE: '+str(conn)

		# TODO IF SteamMultiplayerPeer DOESN'T NEED THIS, MOVE THIS BELOW
		id = lobby_id
		owner_id = Steam.getSteamID()
		var my_name: String = NetworkLobby._limit_string_to_size(Steam.getPersonaName(), 20)
		Steam.setLobbyData(id, "name", (my_name+"'s Lobby"))
		Steam.setLobbyJoinable(id, true)

		var peer = SteamMultiplayerPeer.new()
		var error = peer.create_host(0) # this is virtual port not player limit do not change
		if error != OK:
			return "ERROR CREATING HOST CLIENT\nCODE: " + str(error)

		multiplayer_peer = peer
		players[1] = {"name": my_name, "id": Steam.getSteamID()}
		Steam.allowP2PPacketRelay(true)											# TODO Remove, this should be redundant
		return ""


	# Cleanup
	func _notification(what: int) -> void:
		match what:
			NOTIFICATION_PREDELETE:
				multiplayer_peer.close()
				if id != 0: Steam.leaveLobby(id)
			#NOTIFICATION_CRASH:												# TODO TEST IF THIS IS NEEDED
