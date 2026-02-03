@abstract
class_name MultiplayerLobby
extends Object


## Owner user id. This is not nessessarily the peer_id from multiplayer.get_unique_id().
## With steam it is the account id.
#var owner_id: int = 0															# TODO Consider removing this...? since Steam.getLobbyOwner() and peer_id 1 is always the owner / host
																				# Could be a getter func instead, since a third party account system might have their own account id's

## The [MultiplayerPeer] used in the connection. This can be used as the multiplayer_peer for
## any scene, like the actual game scene. [br]
## This is the same as Lobby.multiplayer.multiplayer_peer, set by the various join funcs.
var multiplayer_peer: MultiplayerPeer

## API to get the local users name. With [SteamMultiplayerLobby] it is the account name.
@abstract func get_user_name() -> String

## Gets the local users user_id. This may be different from the peer_id, wich you get from
## multiplayer.get_unique_id() or multiplayer.get_peers().
@abstract func get_user_id() -> int																	# TODO REMOVE, THIS IS USELESS OUTSIDE OF EACH LOBBY IMPLEMENTATION.
																									# TODO MAKE A is_lobby_owner() GETTER

## Start the connection to join / host a game, based on parameters from the [MultiplayerLobby] implementation. [br]
## Returns false if the parameters or other local step failed. True means you are attempting to host/join and
## can expect a [signal connected_as_client] or [signal connected_as_host] or [signal disconnected].
@abstract func initiate_connection() -> bool

## Successfully hosted or joined as client
signal connected_as_client																			# TODO Does it matter if it connected as client or host in Lobby or elsewhere?
signal connected_as_host

## Disconnect as host / client, or failed lobby_entered attempt
signal disconnected(message:String)

## Emited when the multiplayer peer is set. Only useful during initialisation, to avoid missing any "peer_connected" signals
signal multiplayer_peer_set(peer: MultiplayerPeer)


# TODO Chat messages, recieve and send signals...?
# TODO Chat send func
# TODO Chat history...?
