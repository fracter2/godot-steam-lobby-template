class_name SteamLobby extends Node

# NOTE DEPENDS ON GODOTSTEAM and 


# TODO This node shall manage the connection to hosts/clients, including how to host / join and what
# to do when it fails, and what to do when it quits or recieved a disconnect... and so on.
# 
# Plus basic player info
var lan: bool = false
var lobby_id: int = 0
var players : Dictionary = {}

signal players_changed
signal display_error(message:String)

func is_active() -> bool: return false		# TODO Return true if online+hosting/joined

#
# ---- MAIN CALLBACKS ----
#
func _ready():
	OS.set_environment("SteamAppID", str(480))									# TODO Clarify 480. Is it "Space Wars" ?
	OS.set_environment("SteamGameID", str(480))									# TODO Clarify difference between AppID and GameID
	Steam.steamInit(false, 480)													# TODO Isn't the arg order reversed? TRY
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.join_requested.connect(_on_lobby_join_requested)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	_check_command_line()

func _process(_d:float) -> void:
	Steam.run_callbacks()

#
# ---- API ----
#
func leave_lobby() -> void:													# TODO Law of demeter... also uses Steam.leaveLobby()... that really should be wrapped private
	# TODO GO TO MAIN MENU
	if !lan:																	# TODO This check is both redundant and dangerous (to gkeep track of). This should be handled by RAII class wrappers for each state.
		Steam.leaveLobby(lobby_id)
	multiplayer.multiplayer_peer.close()
	players.clear()

@rpc("any_peer")	# TODO This should be reliable
func sync_info(name_: String, id: int) -> void:
	var peer_id = multiplayer.get_remote_sender_id()
	if lan:
		players[peer_id] = {"name": "Player " + str(len(multiplayer.get_peers())), "id": id}
	else:
		players[peer_id] = {"name": name_, "id": id}
	var minimum_data = {}
	for p in players:
		minimum_data[p] = {"name": players[p]["name"], "id": players[p]["id"]}
	_receive_player_data.rpc(minimum_data, peer_id)
	players_changed.emit()

#
# ---- LOCAL UTIL ----
#
@rpc			# TODO This should be reliable
func _receive_player_data(data : Dictionary, _id:int) -> void:
	players = data
	players_changed.emit()

func _get_fail_response_description(response: int) -> String:
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
func _on_lobby_created(conn, id) -> void:
	if conn != 1:
		display_error.emit('ERROR CREATING STEAM LOBBY\nCODE: '+str(conn))
	
	lobby_id = id
	var my_name : String = Steam.getPersonaName()
	if len(my_name) > 17:
		my_name = my_name.substr(0,17) + '...'
	Steam.setLobbyData(lobby_id, "name", (my_name+"'s Lobby"))
	Steam.setLobbyJoinable(lobby_id, true)
	var multiplayer_peer = SteamMultiplayerPeer.new()
	var error = multiplayer_peer.create_host(0) # this is virtual port not player limit do not change
	if error != OK:
		multiplayer_peer.close()
		Steam.leaveLobby(lobby_id)
		display_error.emit("ERROR CREATING HOST CLIENT\nCODE: " + str(error))
		return
		
	multiplayer.set_multiplayer_peer(multiplayer_peer)
	players[1] = {"name": my_name, "id": Steam.getSteamID()}
	Steam.allowP2PPacketRelay(true)
	#_transition_to_lobby() TODO consider callback
		

func _on_lobby_joined(lobby: int, _permissions: int, _locked: bool, response: int) -> void:			# TODO Consider RAII Wrapper struct with contructor / destructor
	if response == 1:															# TODO Denest
		var id = Steam.getLobbyOwner(lobby)
		if id != Steam.getSteamID():											# TODO Clarify what it is checking... that we aren't the host?
			lobby_id = lobby
			players[1] = {"name": Steam.getFriendPersonaName(id), "id": id}		# TODO Make player info struct
			var multiplayer_peer = SteamMultiplayerPeer.new()
			var error = multiplayer_peer.create_client(id, 0)
			if error != OK:
				multiplayer_peer.close()										# TODO Wrap this cleanup in RAII if possible (dedicated join-node with destructor)
				Steam.leaveLobby(lobby_id)
				display_error.emit("ERROR CREATING CLIENT\nCODE: " + str(error))
				return
			multiplayer.set_multiplayer_peer(multiplayer_peer)
	else:
		display_error.emit(_get_fail_response_description(response))

func _on_lobby_join_requested(this_lobby_id: int, _friend_id: int) -> void:
	lan = false
	Steam.joinLobby(int(this_lobby_id))

func _on_connected_to_server() -> void:
	var id = multiplayer.get_unique_id()
	if lan:
		sync_info.rpc("", id)
	else:
		var my_name : String = Steam.getPersonaName()
		if len(my_name) > 17:
			my_name = my_name.substr(0,17) + '...'
		players[id] = {"name": my_name, "id": Steam.getSteamID()}
		sync_info.rpc(players[id]["name"], players[id]["id"])

func _on_peer_disconnected(id: int) -> void:
	if id == 1:																	# TODO Clarify that this is the server(?)
		leave_lobby()
	else:
		players.erase(id)
		players_changed.emit()

func _on_connection_failed() -> void:
	multiplayer.multiplayer_peer.close()
	display_error.emit('FAILED TO CONNECT...')

func host_steam() -> void:
	lan = false
	Steam.createLobby(Steam.LOBBY_TYPE_FRIENDS_ONLY, 4) # 4 player lobby
	



	
