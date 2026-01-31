@abstract
class_name MultiplayerLobbyAPI	# TODO Consider renaming to just MultiplayerLobby
extends RefCounted

## Lobby id. May be the same as Owner ID, like with EnetMultiplayerLobby
var id: int = 0	# TODO Rename to lobby_id for extra clarity

## Owner user id. This is not nessessarily the peer_id from multiplayer.get_unique_id().
## With steam it is the account id.
var owner_id: int = 0														# TODO Consider removing this...? since Steam.getLobbyOwner() and peer_id 1 is always the owner / host
																			# Could be a getter func instead, since a third party account system might have their own account id's
## Player info [Dictionary].
var players : Dictionary = {}

## The [MultiplayerPeer] used in the connection. This can be used as the multiplayer_peer for
## any scene, like the actual game scene. [br]
## This is the same as Lobby.multiplayer.multiplayer_peer, set by the various join funcs.
var multiplayer_peer: MultiplayerPeer

## API to get the local users name. With SteamMultiplayerLobby it is the account name.
@abstract func get_user_name() -> String

## Gets the local users user_id. This may be different from the peer_id, wich you get from
## multiplayer.get_unique_id() or multiplayer.get_peers().
@abstract func get_user_id() -> int

## Start the connection to join / host a game, based on parameters from the [MultiplayerLobbyAPI] implementation. [br]
## Returns false if the parameters or other local step failed. True means you are attempting to host/join and
## can expect a [signal connected_as_client] or [signal connected_as_host] or [signal disconnected].
@abstract func initiate_connection() -> bool

## Successfully hosted or joined as client
signal connected_as_client
signal connected_as_host

## Disconnect as host / client, or failed connected attempt
signal disconnected(message:String)

##
signal player_info_changed(peer_id: int, update_type: PLAYER_INFO_UPDATE, param: String, value: Variant)		# TODO Sepparate into multiple signals for property change / remove / player added / removed

# TODO Chat messages, recieve and send signals...?
# TODO Chat send func
# TODO Chat history...?

enum PLAYER_INFO_UPDATE {
	PROPERTY_CHANGED,
	PROPERTY_REMOVED,
	PLAYER_ADDED,
	PLAYER_REMOVED
}
