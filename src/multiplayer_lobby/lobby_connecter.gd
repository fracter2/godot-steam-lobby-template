class_name LobbyConnecter
extends Node
## When entering tree, sets the [member multiplayer.multiplayer_peer] for the current scene in the tree.
## If the lobby disconnects, and [member quit_on_lobby_missing] is [code]true[/code], the lobby quits to main menu.[br]
## This class is meant to represent the entire scene's dependancy on the Lobby multiplayer connection.


@export var quit_on_lobby_missing: bool = true									# TODO consider having it instead PAUSE the world + ui prompt


#
# ---- PROCEDURE ----
#

func _ready() -> void:
	if Lobby.is_in_lobby():
		_on_lobby_entered()
	else:
		if quit_on_lobby_missing:
			_quit_to_menu()
		else:
			push_warning("Started game without being in a lobby! Is this ok?")
			Lobby.lobby_entered.connect(_on_lobby_entered, ConnectFlags.CONNECT_ONE_SHOT)			# Oneshot to clarify use-case

	Lobby.lobby_exiting.connect(_on_lobby_exiting)													# NOTE Consider deffered, to avouid quitting in the middle of processing... maybe helpfull?
	multiplayer.server_disconnected.connect(_on_lobby_exiting.bind("Server disconnected"))


#
# ---- SIGNALS ----
#

func _on_lobby_entered() -> void:
	Log.pprint("GAME: JUST JOINED AS PEER %d" % [multiplayer.get_unique_id()])
	get_tree().current_scene.multiplayer.multiplayer_peer = Lobby.multiplayer.multiplayer_peer


func _on_lobby_exiting(message: String) -> void:
	Log.pprint("Quit level, message: %s" % message)
	if quit_on_lobby_missing:
		_quit_to_menu()


func _quit_to_menu() -> void:
	if is_inside_tree():
		get_tree().change_scene_to_file(PATHS.MAIN_MENU)
