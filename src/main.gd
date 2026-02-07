extends Node2D


const GAME = preload("uid://dx0gencnp27xs")



#
# ---- PROCEDURE ----
#

func _enter_tree() -> void:
	Lobby.lobby_entered.connect(_on_connected)



#
# ---- SIGNALS ----
#

func _on_connected() -> void:
	get_tree().change_scene_to_packed(GAME)
