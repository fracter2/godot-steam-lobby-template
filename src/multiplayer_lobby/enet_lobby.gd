class_name EnetMultiplayerLobby
extends MultiplayerLobby

var username: String = "DefaultName"
var init_as_host:bool
var init_ip: String
var init_port: int

func _init(is_host: bool = false, ip: String = "127.0.0.1", port: int = 8080, username_: String = "DefaultName") -> void:
	init_as_host = is_host
	username = username_
	init_ip = ip
	init_port = port

func is_active() -> bool: return false
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
			multiplayer_peer = peer
			_delegate_join_lobby.call_deferred()
			connected_as_client.emit()
			return true

func _delegate_join_lobby() -> void:
	connected_as_client.emit()

func _delegate_host_lobby() -> void:
	connected_as_host.emit()

func _delegate_on_disconnected(message: String) -> void:
	disconnected.emit(message)
