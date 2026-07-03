class_name World
extends Node2D

## This class is meant to be a general use world implementation that can be used as a basis for any kind of level.
## This would be customized or replaced in an actual game.

# TODO MOVE AWAY FROM SCENE ROOT
# TODO MAKE SO IT CAN LOAD LEVEL MAPS				# Or make separate node!
# TODO MAKE SO IT CAN LOAD SAVE FILES				# Or make separate node!
# TODO MAKE SO SERVER SENDS STATIC WORLD STATE		# Or make separate node!

@export var quit_on_lobby_disconnect: bool = true								# TODO SEPARATE TO DEDICATED NODE (consider having it instead PAUSE the world + ui prompt)

@export_group("References")
@export var player_branch_manager: ClientSpawnerManager
@export var server_branch: Node2D
@export var local_branch: Node2D

static var singleton: World = null


#
# ---- PROCEDURE ----
#

func _enter_tree() -> void:
	assert(singleton == null)
	singleton = self


func _ready() -> void:
	if Lobby.is_in_lobby():
		_on_lobby_entered()
	else:
		push_warning("Started game without being in a lobby! Is this ok?")
		Lobby.lobby_entered.connect(_on_lobby_entered, ConnectFlags.CONNECT_ONE_SHOT)				# Oneshot to clarify use-case

	Lobby.lobby_exiting.connect(_on_lobby_exiting)	#, ConnectFlags.CONNECT_DEFERRED # NOTE Deffered to avouid quitting in the middle of processing... Theoretically helpfull
	multiplayer.server_disconnected.connect(_on_lobby_exiting.bind("Server disconnected"))


func _exit_tree() -> void:
	# TODO NOTIFY SERVER BY DISCONNECTING FORMALLY (THROUGH LOBBY MAYBE?)
	#multiplayer.disconnect() # NOTE NOT THIS, SINCE THE SAME PEER IS USED FOR LOBBY!
	# NOTE Some errors may appear of "on_sync_recieve: Ignoring sync data from non-authority or for missing node". THIS IS OK! WE ARE QUITTING! LOL

	singleton = null
	pass


#
# ---- API ----
#


# TODO REPLACE ALL WITH DEDICATED SINGLETONS AND FUNCS


## Adds the node to the tree under [property server_branch], of course with server authority set.
static func spawn_server_owned(node: Node) -> void:													# TODO REPLACE WITH SINGLETON EQUIVOLENT
	singleton.server_branch.add_child(node, true)


## Adds the node to the tree under [property local_entities]. Note that client-local (aka clientside or client-only) spawns don't
## have a [MultiplayerSpawner] atached, but still has the multiplayer authority set to default (server, id 1).
static func spawn_client_local(node: Node) -> void:													# TODO REPLACE WITH SINGLETON EQUIVOLENT
	singleton.local_branch.add_child(node, true)


#
# ---- SIGNALS ----
#

func _on_lobby_entered() -> void:
	Log.pprint("GAME: JUST JOINED AS PEER %d" % [multiplayer.get_unique_id()])
	multiplayer.multiplayer_peer = Lobby.multiplayer.multiplayer_peer
	assert(multiplayer.multiplayer_peer != null, "obviously this shoulda not be null")


func _on_lobby_exiting(message: String) -> void:
	Log.pprint("Quit level, message: %s" % message)
	if quit_on_lobby_disconnect and is_inside_tree():
		get_tree().change_scene_to_file(PATHS.MAIN_MENU)
