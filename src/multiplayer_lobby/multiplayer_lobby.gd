@abstract
class_name MultiplayerLobby
extends Object


## The [MultiplayerPeer] used in the connection. This can be used as the multiplayer_peer for
## any scene, like the actual game scene. [br]
## This is the same as Lobby.multiplayer.multiplayer_peer, set by the various join funcs.
var multiplayer_peer: MultiplayerPeer

## API to get the local users name. With [SteamMultiplayerLobby] it is the account name.
@abstract func get_user_name() -> String

##
@abstract func is_lobby_owner() -> bool											# TODO ALLOW QUERYING PEER_ID OF OWNER? IS IT ALWAYS 1 EVEN FOR STEAM?

## Start the connection to join / host a game, based on parameters from the [MultiplayerLobby] implementation. [br]
## Returns false if the parameters or other local step failed. True means you are attempting to host/join and
## can expect a [signal connected_as_client] or [signal connected_as_host] or [signal disconnected].
@abstract func initiate_connection() -> bool

## Successfully hosted or joined as client
@warning_ignore("unused_signal") signal connected_as_client
@warning_ignore("unused_signal") signal connected_as_host

## Disconnect as host / client, or failed lobby_entered attempt
@warning_ignore("unused_signal") signal disconnected(message:String)
