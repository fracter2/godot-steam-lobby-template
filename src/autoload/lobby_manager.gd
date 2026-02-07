extends Node

var lobby_instance: MultiplayerLobby = null

## A non-recoverable issue has occured and the [MultiplayerLobby] has been destroyed.
signal critical_error(message:String)

## Successfully hosted or joined as client
signal lobby_entered

## Disconnect as host / client, or failed lobby_entered attempt
signal lobby_exited(message:String) # lobby_exited


## Player info [Dictionary].
var players : Dictionary[int, PlayerInfo] = {}

## Emits when a key in the player info dictionary is set.
signal player_added				(player: PlayerInfo)
signal player_removed			(player: PlayerInfo)
signal player_name_set			(new_name: StringName, player: PlayerInfo)
signal player_nickname_set		(new_name: StringName, player: PlayerInfo)
signal player_steam_id_set		(steam_id: int, player: PlayerInfo)
signal player_small_avatar_set	(avatar: Image, player: PlayerInfo)
signal player_medium_avatar_set	(avatar: Image, player: PlayerInfo)
signal player_large_avatar_set	(avatar: Image, player: PlayerInfo)


#
# ---- MAIN CALLBACKS ----
#
func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = -1														# TODO Consider global constants CONST autoload
	process_physics_priority = -1


func _enter_tree() -> void:
	critical_error.connect(_on_critical_error)

	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	#multiplayer.server_disconnected

	Steam.join_requested.connect(_on_lobby_join_requested)
	#Steam.join_game_requested													# TODO Consider this if above doesn't work


func _ready() -> void:
	# We wait a bit more in case any node in the main scene connect to Lobby signals at _on_ready()
	await get_tree().current_scene.ready
	_check_launch_commands()


#
# ---- API ----
#

func is_in_lobby() -> bool:
	return lobby_instance != null

#func is_lobby_owner() -> bool:
#	return lobby_instance.owner_id == lobby_instance.get_user_id()

## Returns the result of the initiation [b]attempt[/b]. [signal lobby_entered] and [signal lobby_exited]
## emit when the result is granted (imagine it like waiting for the host / setup to respond) [br] [br]
## Lobby argument is freed on return false, to enforce intended use (Lobbies should only persist in this autoload)
func initiate_lobby(lobby: MultiplayerLobby) -> bool:
	if is_in_lobby():
		lobby.free()	# Dissallow the lobby object to be used for anything else! Because it should only be useful here!
		return false

	lobby.connected_as_client.connect(_on_connected_as_client)					# TODO Consider internal func for connecting / disconnecting...
	lobby.connected_as_host.connect(_on_connected_as_host)
	lobby.disconnected.connect(_on_disconnected)
	lobby_instance = lobby	# NOTE Set here instead of in "if lobby.initiate_connection(): " to avoid signal callbacks from init success trying to access lobby_instance.

	if lobby.initiate_connection():
		return true

	else:
		lobby_instance = null
		# TODO REMOVE THESE DISCONNECTS, lobby.free() should take care of it... unless the notification_pre_delete may influence
		lobby.connected_as_client.disconnect(_on_connected_as_client)
		lobby.connected_as_host.disconnect(_on_connected_as_host)
		lobby.disconnected.disconnect(_on_disconnected)

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
func clear_player_info(id: int) -> bool:
	if not players.has(id):
		return false

	var info_res: PlayerInfo = players.get(id)
	players.erase(id)
	player_removed.emit(id, info_res)
	return true


##
func add_new_player_info(peer_id: int) -> bool:
	if not multiplayer.get_peers().has(peer_id) and peer_id != multiplayer.get_unique_id():
		print_debug("add_new_player_info(%d) called when peer doesn't exist!" % peer_id)
		return false

	if players.has(peer_id):
		print_debug("add_new_player_info(%d) called when peer info is already registered!" % peer_id)
		return false

	var info: PlayerInfo = PlayerInfo.new(peer_id)
	players.set(peer_id, info)
	_wrap_player_info_signals(info)
	player_added.emit(peer_id, info)
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

	var id: int = multiplayer.get_unique_id()
	add_new_player_info(id)
	players[id].display_name = lobby_instance.get_user_name()

	for peer_id: int in multiplayer.get_peers():
		if players.has(peer_id):
			print("Already added this peer_id to info")
		else:
			add_new_player_info(peer_id)

	lobby_entered.emit()


func _on_connected_as_host() -> void:
	print("Lobby: connected as HOST with %d peers!" % multiplayer.get_peers().size())
	multiplayer.multiplayer_peer = lobby_instance.multiplayer_peer

	var id: int = multiplayer.get_unique_id()
	add_new_player_info(id)
	players[id].display_name = lobby_instance.get_user_name()
	lobby_entered.emit()


func _on_disconnected(message: String) -> void:
	leave_lobby(message)



func _wrap_player_info_signals(player_info: PlayerInfo) -> void:
	# TODO CHECK IF IT IS ALREADY BOUND

	player_info.display_name_set.connect(_on_player_name_set.bind(player_info))
	player_info.nickname_set.connect(_on_player_nickname_set.bind(player_info))
	player_info.steam_id_set.connect(_on_player_steam_id_set.bind(player_info))
	player_info.avatar_small_set.connect(_on_player_small_avatar_set.bind(player_info))
	player_info.avatar_medium_set.connect(_on_player_medium_avatar_set.bind(player_info))
	player_info.avatar_large_set.connect(_on_player_large_avatar_set.bind(player_info))


# Signal call wrappers for use with PlayerInfo signal
func _on_player_name_set(new_name: StringName, player: PlayerInfo) -> void:
	player_name_set.emit(new_name, player)

func _on_player_nickname_set(new_name: StringName, player: PlayerInfo) -> void:
	player_nickname_set.emit(new_name, player)

func _on_player_steam_id_set(steam_id: int, player: PlayerInfo) -> void:
	player_steam_id_set.emit(steam_id, player)

func _on_player_small_avatar_set(avatar: Image, player: PlayerInfo) -> void:
	player_small_avatar_set.emit(avatar, player)

func _on_player_medium_avatar_set(avatar: Image, player: PlayerInfo) -> void:
	player_medium_avatar_set.emit(avatar, player)

func _on_player_large_avatar_set(avatar: Image, player: PlayerInfo)-> void:
	player_large_avatar_set.emit(avatar, player)

#
# ----
#
