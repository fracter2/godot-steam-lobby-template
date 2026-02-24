class_name EnetLobbyBackend extends Node

## The point of this node is to provide RPC functions to an active [EnetMultiplayerLobby] instance.
## It should not be spawned sepparately and should be deleted alongside the [EnetMultiplayerLobby] it was spawned by.
##
## More specifically it provides @rpc funcs for Syncing username.
## Might be useful for potentially... Sending chats? Updating Lobby metadata (public/private)?


var lobby: EnetMultiplayerLobby = null


func _init(lobby_instance: EnetMultiplayerLobby) -> void:
	lobby = lobby_instance
	name = "EnetBackend"


func _enter_tree() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	# NOTE It won't work if connected using multiplayer_peer.peer_connected!
	# It complains that the MultiplayerPeer is not set! Since it occurs before MultiplayerAPI.multiplayer_peer is set!


@rpc("any_peer", "call_remote", "reliable")
func sync_player_name(peer_id: int, username: String) -> void:
	if not Lobby.players.has(peer_id):
		Log.pprint("EmetLobbyBackend: tried to _sync_player_name() with non-excistent player peer_id: %d. Username: %s" % [peer_id, username])
		return

	Lobby.players[peer_id].display_name = username


func _on_peer_connected(id: int) -> void:
	sync_player_name.rpc_id(id, multiplayer.get_unique_id(), lobby.username)
