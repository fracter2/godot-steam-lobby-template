@abstract
class_name MultiplayerLobby
extends Object

## Lobby id. May be the same as Owner ID, like with EnetMultiplayerLobby
var lobby_id: int = 0

## Owner user id. This is not nessessarily the peer_id from multiplayer.get_unique_id().
## With steam it is the account id.
var owner_id: int = 0															# TODO Consider removing this...? since Steam.getLobbyOwner() and peer_id 1 is always the owner / host
																				# Could be a getter func instead, since a third party account system might have their own account id's
## Player info [Dictionary].
var players : Dictionary = {}													# TODO Consider a dedicated info class... even as a simple Dictionary wrapper with embedded peer_id + user_id + name...

## The [MultiplayerPeer] used in the connection. This can be used as the multiplayer_peer for
## any scene, like the actual game scene. [br]
## This is the same as Lobby.multiplayer.multiplayer_peer, set by the various join funcs.
var multiplayer_peer: MultiplayerPeer

## API to get the local users name. With [SteamMultiplayerLobby] it is the account name.
@abstract func get_user_name() -> String

## Gets the local users user_id. This may be different from the peer_id, wich you get from
## multiplayer.get_unique_id() or multiplayer.get_peers().
@abstract func get_user_id() -> int

## Start the connection to join / host a game, based on parameters from the [MultiplayerLobby] implementation. [br]
## Returns false if the parameters or other local step failed. True means you are attempting to host/join and
## can expect a [signal connected_as_client] or [signal connected_as_host] or [signal disconnected].
@abstract func initiate_connection() -> bool

## Successfully hosted or joined as client
signal connected_as_client																			# TODO Does it matter if it connected as client or host in Lobby or elsewhere?
signal connected_as_host

## Disconnect as host / client, or failed lobby_entered attempt
signal disconnected(message:String)

## Emited when a parameter is added or changed. The parameter and value are provided for convenience.
signal player_info_set(peer_id: int, param: String, value: Variant)

## Not sure why it would be useful to selectively remove parameters, but here we go anyway...
signal player_info_removed(peer_id: int, param: String)												# TODO CONSIDER YAGNI

## Emited when an entire player_id is removed from [member players]. [br]
## The opposite equivolent would be just checking if a player joined through the Lobby autoload
## or through [MultiplayerPeer] or [MultiplayerAPI]
signal player_info_cleared(peer_id: int)															# TODO CONSIDER YAGNI


# TODO Chat messages, recieve and send signals...?
# TODO Chat send func
# TODO Chat history...?
