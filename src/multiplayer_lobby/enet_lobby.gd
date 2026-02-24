class_name EnetMultiplayerLobby
extends MultiplayerLobby

var username: String = "DefaultName"

var init_as_host:bool
var init_ip: String
var init_port: int
var max_clients: int = 1000	# NOTE limited by ENetMultiplayerPeer.create_server

var backend: EnetLobbyBackend = null

#
# ---- PROCEDURE ----
#

func _init(is_host: bool = false, ip: String = "127.0.0.1", port: int = 8080, username_: String = "DefaultName") -> void:
	init_as_host = is_host
	username = username_
	init_ip = ip
	init_port = port


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PREDELETE:
			if not multiplayer_peer.get_connection_status() == multiplayer_peer.CONNECTION_DISCONNECTED:
				multiplayer_peer.close()
			if backend != null and not backend.is_queued_for_deletion():
				backend.queue_free()
				backend = null


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
	backend = EnetLobbyBackend.new(self)
	Lobby.add_child(backend)

	if init_as_host:
		return _initiate_as_host()
	else:
		return _initiate_as_client()


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

	connected_as_client.emit()	# NOTE Lobby will here create a player_info for each peer
	return true


func _create_multiplayer_peer() -> void:
	multiplayer_peer = ENetMultiplayerPeer.new()
