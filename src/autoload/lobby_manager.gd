extends Node

var lobby_instance: MultiplayerLobby = null

## Player info [Dictionary].
var players : Dictionary[int, PlayerInfo] = {}


## A non-recoverable issue has occured and the [MultiplayerLobby] has been destroyed.
signal critical_error(message:String)

## Successfully hosted or joined as client
signal lobby_entered

## Disconnect as host / client, or failed lobby_entered attempt
signal lobby_exited(message:String) # lobby_exited

## Emits when a key in the player info dictionary is set.
signal player_info_set(peer_id: int, param: String, value: Variant)

## Emits when a key in the player info dictionary is removed. However usefull that may be.
#signal player_info_removed(peer_id: int, param: String)

## Emits when a player in the player info resouce for a peer is removed (like when the peer disconnects). [br]
## The info_resource contains all info that was dropped.
signal player_info_cleared(peer_id: int, info_resource: PlayerInfo)


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
	#Steam.join_game_requested													# TODO Consider this if above doesn't work

	# TODO Delegate these callbacks
	multiplayer.connected_to_server.connect(_on_connected_to_server)			# NOTE So this only calls locally once.
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	#multiplayer.server_disconnected

	_check_launch_commands()

#
# ---- API ----
#

func is_in_lobby() -> bool:
	return lobby_instance != null

func is_lobby_owner() -> bool:
	return lobby_instance.owner_id == lobby_instance.get_user_id()

## Returns the result of the initiation [b]attempt[/b]. [signal lobby_entered] and [signal lobby_exited]
## emit when the result is granted (imagine it like waiting for the host / setup to respond) [br]
## [br]
## Lobby argument is freed on return false, to enforce intended use (Lobbies should only persist in this autoload)
func initiate_lobby(lobby: MultiplayerLobby) -> bool:
	if is_in_lobby():
		lobby.free()	# Dissallow the lobby object to be used for anything else! Because it should only be useful here!
		return false

	lobby.connected_as_client.connect(_on_connected_as_client)					# TODO Consider internal func for connecting / disconnecting...
	lobby.connected_as_host.connect(_on_connected_as_host)
	lobby.disconnected.connect(_on_disconnected)
	#lobby.multiplayer_peer_set.connect(_on_multiplayer_peer_set)

	if lobby.initiate_connection():
		lobby_instance = lobby
		return true

	else:
		# TODO REMOVE THESE DISCONNECTS, lobby.free() should take care of it... unless the notification_pre_delete may influence
		lobby.connected_as_client.disconnect(_on_connected_as_client)
		lobby.connected_as_host.disconnect(_on_connected_as_host)
		lobby.disconnected.disconnect(_on_disconnected)
		#lobby.multiplayer_peer_set.disconnect(_on_multiplayer_peer_set)

		lobby.free()
		return false


func leave_lobby(message: String) -> void:
	if not is_in_lobby():
		print_debug("Tried to quit lobby when not in a lobby")
		return

	for id: int in multiplayer.get_peers():
		clear_player_info(id)

	lobby_instance.free() 														# NOTE This will handle all the cleanup internally
	lobby_instance = null														# TODO Create a DummyLobby or NotALobbyLobby or SoloLobby to act as a stand-in... so funcs don't have to validate for everything...
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	lobby_exited.emit(message)
	print("Left lobby! Message: %s" % message)


##
func has_player_info(peer_id: int, key: String) -> bool:
	if players.has(peer_id):
		return players[peer_id].info.has(key)
	else:
		return false

##
func get_player_info(peer_id: int, key: String, default: Variant = null) -> Variant:
	if players.has(peer_id):
		return players[peer_id].info.get(key, default)
	else:
		return default

##
func set_player_info(peer_id: int, key: String, value: Variant) -> bool:
	if not players.has(peer_id):
		return false

	players[peer_id].info.set(key, value)
	player_info_set.emit(peer_id, key, value)
	return true


##
func clear_player_info(id: int) -> bool:
	if not players.has(id):
		return false

	var info_res: PlayerInfo = players.get(id)
	players.erase(id)
	player_info_cleared.emit(id, info_res)
	return true


##
func add_new_player_info(id: int) -> bool:
	if not multiplayer.get_peers().has(id) and id != multiplayer.get_unique_id():
		print_debug("add_new_player_info(%d) called when peer doesn't exist!" % id)
		return false

	if players.has(id):
		print_debug("add_new_player_info(%d) called when peer info is already registered!" % id)
		return false

	players.set(id, PlayerInfo.new())
	set_player_info(id, "id", id)
	return true


#
# ---- LOCAL UTIL ----
#

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


func _on_lobby_join_requested(this_lobby_id: int, friend_id: int) -> void:
	print("Steam lobby join requested, id: %d friend_name: %s" % [this_lobby_id, Steam.getFriendPersonaName(friend_id)])
	if is_in_lobby():
		print("Leaving lobby to join requested lobby!")
		leave_lobby("Accepted request to join another lobby")

	initiate_lobby(SteamMultiplayerLobby.new(this_lobby_id, false))



func _on_connected_to_server() -> void:
	print("Lobby: Connected to server!")
	var id: int = multiplayer.get_unique_id()
	var my_name : String = lobby_instance.get_user_name()

	add_new_player_info(id)
	set_player_info(id, "name", my_name)


func _on_peer_connected(id: int ) -> void:
	print("Lobby: Peer connected, peer_id: %d" % id)
	if players.has(id): print("Peer was already registered... prob by lobby instance right before...")
	else: add_new_player_info(id)


func _on_peer_disconnected(id: int) -> void:
	if id == 1:
		leave_lobby("Host left lobby")			# TODO This should be handled by the lobby!!
	else:
		clear_player_info(id)


func _on_connection_failed() -> void:
	critical_error.emit('CONNECTION FAILED!')


func _on_connected_as_client() -> void:
	print("Lobby: connected as CLIENT with %d peers!" % multiplayer.get_peers())
	multiplayer.multiplayer_peer = lobby_instance.multiplayer_peer

	add_new_player_info(multiplayer.get_unique_id())
	set_player_info(multiplayer.get_unique_id(), "name", lobby_instance.get_user_name())

	for peer_id: int in multiplayer.get_peers():
		if players.has(peer_id):
			print("Already added this peer_id to info")
		else:
			add_new_player_info(peer_id)

	lobby_entered.emit()


func _on_connected_as_host() -> void:
	print("Lobby: connected as HOST with %d peers!" % multiplayer.get_peers().size())
	multiplayer.multiplayer_peer = lobby_instance.multiplayer_peer

	add_new_player_info(multiplayer.get_unique_id())
	set_player_info(multiplayer.get_unique_id(), "name", lobby_instance.get_user_name())
	lobby_entered.emit()


func _on_disconnected(message: String) -> void:
	leave_lobby(message)


#func _on_multiplayer_peer_set(peer: MultiplayerPeer) -> void:
#	print("Lobby setting new multiplayer peer")
#	multiplayer.multiplayer_peer = peer

### Simple wrapper over [member lobby_instance] signal, for convenience
#func _on_player_info_set(peer_id: int, param: String, value: Variant) -> void:
	#player_info_set.emit(peer_id, param, value)
#
### Simple wrapper over [member lobby_instance] signal, for convenience
#func _on_player_info_removed(peer_id: int, param: String) -> void:
	#player_info_removed.emit(peer_id, param)
#
### Simple wrapper over [member lobby_instance] signal, for convenience
#func _on_player_info_cleared(peer_id: int) -> void:
	#player_info_cleared.emit(peer_id)

#
# ----
#
