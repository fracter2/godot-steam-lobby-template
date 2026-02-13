extends Node2D


const GAME = preload(PATHS.DEMO_GAME)



#
# ---- PROCEDURE ----
#

func _enter_tree() -> void:
	Lobby.lobby_entered.connect(_on_connected)



#
# ---- SIGNALS ----
#

func _on_connected() -> void:
	get_tree().change_scene_to_packed.call_deferred(GAME)	# NOTE Call deffered to avoid complaints when connecting through launch args
