class_name NetworkLobby extends Node

# NOTE DEPENDS ON GODOTSTEAM and 

const default_app_id: int = 480 												# NOTE This is SpaceWars.
const app_id: int = default_app_id										# NOTE Replace this when you get your app id!

# TODO This node shall manage the connection to hosts/clients, including how to host / join and what
# to do when it fails, and what to do when it quits or recieved a disconnect... and so on.
# 
# Plus basic player info
var lobby_instance: NetworkLobbyHandler = null

signal players_changed
signal critical_error(message:String)
signal disconnected(message:String)

func is_active() -> bool: return false		# TODO Return true if online+hosting/joined

#
# ---- MAIN CALLBACKS ----
#
func _ready():																	#
	critical_error.connect(_on_critical_error)
	OS.set_environment("SteamAppID", str(app_id))
	OS.set_environment("SteamGameID", str(app_id))								# TODO Clarify difference between AppID and GameID
	Steam.steamInit(app_id, false)
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.join_requested.connect(_on_lobby_join_requested)
	
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	#multiplayer.peer_connected
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	_check_command_line()
	

func _process(_d:float) -> void:
	Steam.run_callbacks()

#
# ---- API ----
#

func join_steam_lobby() -> bool:
	if lobby_instance != null: return false
	
	return false
	
func join_enet_lobby() -> bool:
	if lobby_instance != null: return false
	
	return false

func leave_lobby() -> void:
	lobby_instance.free()														# NOTE This will handle all the cleanup internally
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()					# TODO This prob not needed. Reconsider
	disconnected.emit("Left network lobby normally")
	# TODO GO TO MAIN MENU


@rpc("any_peer", "reliable")
func sync_info(name_: String, id: int) -> void:														# TODO NOTE This is meant to JUST send the info of all players TO THE REMOTE_SENDER. consider renaming
	var peer_id = multiplayer.get_remote_sender_id()
	if lobby_instance.players.has(peer_id):
		push_warning("attemped to sync_info() already existing peer")
		return
		
	lobby_instance.players[peer_id] = {"name": name_, "id": id}
	
	# Send only the minimum data...
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

static func _get_fail_response_description(response: int) -> String:
	match response:
		1:  return "OK."
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

static func _limit_string_to_size(txt: String, size: int) -> String:
	assert(size > 3) 
	if txt.length() > size:														# TODO Clarify max name length const
		txt = txt.substr(0, size-3) + '...'
	return txt

# TODO Rename
func _check_command_line() -> void:												# TODO This could be a class on it's own, with configurable "if this..." funcs/callables
	var these_arguments: Array = OS.get_cmdline_args()							# ... perhaps as an autoload
	if these_arguments.size() > 0:
		if these_arguments[0] == "+connect_lobby":								# ... since it would be nice to have this rawdogging stopped
			if int(these_arguments[1]) > 0:
				Steam.joinLobby(int(these_arguments[1]))

#	
# ---- SIGNAL CALLBACKS ----
#
func _on_critical_error(_message: String):
	leave_lobby()


func _on_lobby_created(conn: int, id: int) -> void:								# TODO DOESN'T QUIT PREVIOUS LOBBY... does it prevent mutliple lobbies? prob not...
	var steam_lobby: SteamNetworkLobbyHandler = SteamNetworkLobbyHandler.new()
	var err: String = steam_lobby.on_create_lobby(conn, id)
	if err:
		critical_error.emit(err)
		return
	
	lobby_instance = steam_lobby
	multiplayer.multiplayer_peer = lobby_instance.multiplayer_peer


func _on_lobby_joined(lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:			# TODO Consider RAII Wrapper struct with contructor / destructor
	var steam_lobby: SteamNetworkLobbyHandler = SteamNetworkLobbyHandler.new()
	var err: String = steam_lobby.on_join_lobby(lobby_id, _permissions, _locked, response)
	if err:
		critical_error.emit(err)
		return
	
	lobby_instance = steam_lobby
	multiplayer.multiplayer_peer = lobby_instance.multiplayer_peer


func _on_lobby_join_requested(this_lobby_id: int, _friend_id: int) -> void:
	Steam.joinLobby(int(this_lobby_id))


func _on_connected_to_server() -> void:
	var peer_id: int = multiplayer.get_unique_id()
	var my_name : String = _limit_string_to_size(lobby_instance.get_user_name(), 20)
	var my_user_id: int = lobby_instance.get_user_id()
	
	lobby_instance.players[peer_id] = {"name": my_name, "id": my_user_id}		# TODO Optimize sync_ifo logic to only send new data. Bandwidth aint free...
	sync_info.rpc(my_name, my_user_id)


func _on_peer_disconnected(id: int) -> void:
	if id == 1:																	# TODO Clarify that this is the server(?)
		leave_lobby()
	else:
		lobby_instance.players.erase(id)
		players_changed.emit()


func _on_connection_failed() -> void:
	multiplayer.multiplayer_peer.close()
	critical_error.emit('FAILED TO CONNECT...')


func host_steam() -> void:
	Steam.createLobby(Steam.LOBBY_TYPE_FRIENDS_ONLY, 4) # 4 player lobby		# TODO Clarify player limit to a var
	


#
# ---- 
#
@abstract
class NetworkLobbyHandler extends RefCounted:
	var id: int = 0
	var owner_id: int = 0
	var players : Dictionary = {}
	var multiplayer_peer: MultiplayerPeer
	#@abstract func is_active() -> bool
	@abstract func get_user_name() -> String
	@abstract func get_user_id() -> int


class EnetNetworkLobbyHandler extends NetworkLobbyHandler:
	var username: String = "DefaultName"
	
	func is_active() -> bool: return id != 0
	func get_user_name() -> String: return username								# NOTE if there is a non-steam account system, this would be the account name
	func get_user_id() -> int: return multiplayer_peer.get_unique_id()			# NOTE if there is a non-steam account system, this would be the account id



class SteamNetworkLobbyHandler extends NetworkLobbyHandler:
	func is_active() -> bool: return id != 0
	func get_user_name() -> String: return Steam.getPersonaName()
	func get_user_id() -> int: return Steam.getSteamID()
	
	
	# NOTE Returns "" on success
	func on_join_lobby(lobby_id: int, _permissions: int, _locked: bool, response: int) -> String:
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
		players[1] = {"name": Steam.getFriendPersonaName(owner_id), "id": owner_id}				# TODO Make player info struct
		return ""

	# NOTE Returns "" on success
	func on_create_lobby(conn: int, lobby_id: int) -> String:								# TODO DOESN'T QUIT PREVIOUS LOBBY... does it prevent mutliple lobbies? prob not...
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
	

	func _notification(what: int) -> void:
		match what:
			NOTIFICATION_PREDELETE:
				multiplayer_peer.close()
				if id != 0: Steam.leaveLobby(id)
			#NOTIFICATION_CRASH:												# TODO TEST IF THIS IS NEEDED
				

		
