class_name EnetMultiplayerLobby
extends MultiplayerLobby

var username: String = "DefaultName"
var init_as_host:bool
var init_ip: String
var init_port: int

var max_clients: int = 1000	# NOTE limited by ENetMultiplayerPeer.create_server



#
# ---- PROCEDURE ----
#

func _init(is_host: bool = false, ip: String = "127.0.0.1", port: int = 8080, username_: String = "DefaultName") -> void:
	init_as_host = is_host
	username = username_
	init_ip = ip
	init_port = port

#
# ---- API ----
#

func is_active() -> bool: return false
func get_user_name() -> String: return username								# NOTE if there is a (non-steam) account system, this would be the account name

func is_lobby_owner() -> bool:
	if multiplayer_peer == null: return false
	return multiplayer_peer.get_unique_id() == 1


func initiate_connection() -> bool:
	# TODO Validate port and ip

	_create_multiplayer_peer()
	if init_as_host:
		return _initiate_as_host()
	else:
		return _initiate_as_client()


#
# ---- SIGNAL CALLBACKS ----
#

func _on_peer_connected(peer_id: int) -> void:
	if Lobby.players.has(peer_id):
		print_debug("in ENetMultiplayerPeer._on_peer_connected(%d), somehow already have the peer_id in the players[] dict" % peer_id)
	else:
		Lobby.add_new_player_info(peer_id)


func _on_peer_disconnected(peer_id: int) -> void:													# TODO REMOVE THIS IS JUST TO TEST WHAT TRIGGERS FIRST, multiplayer.peer_connected or this
	if Lobby.players.has(peer_id):
		Lobby.clear_player_info(peer_id)
	else:
		print_debug("in ENetMultiplayerPeer._on_peer_disconnected(%d), somehow dont have the peer_id in the players[] dict" % peer_id)


#
# ---- INTERNALS ----
#

func _initiate_as_host() -> bool:
	var error: Error = (multiplayer_peer as ENetMultiplayerPeer).create_server(init_port, max_clients)
	if error != Error.OK:
		push_warning("error while trying to EnetMultiplayerPeer.create_client(), error: " + str(error))
		return false

	connected_as_host.emit()
	return true


func _initiate_as_client() -> bool:
	var error: Error = (multiplayer_peer as ENetMultiplayerPeer).create_client(init_ip, init_port)
	if error != Error.OK:
		push_warning("error while trying to EnetMultiplayerPeer.create_client(), error: " + str(error))
		return false

	#_delegate_join_lobby.call_deferred()										# TODO IS THIS NESSESSARY? MAYBE! Steam behaves more like this
	connected_as_client.emit()	# NOTE Lobby will here create a player_info for each peer
	#(multiplayer_peer as ENetMultiplayerPeer).get_packet()
	#(multiplayer_peer as ENetMultiplayerPeer).get_available_packet_count()
	return true


func _recieve_username(peer_username: String) -> void:
	pass


func _delegate_join_lobby() -> void:
	connected_as_client.emit()

func _delegate_host_lobby() -> void:
	connected_as_host.emit()

func _delegate_on_disconnected(message: String) -> void:
	disconnected.emit(message)


func _create_multiplayer_peer() -> void:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	peer.peer_connected.connect(_on_peer_connected)
	peer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer_peer = peer
	#multiplayer_peer_set.emit(peer)	# TODO CONSIDER REMOVING UNSUED
