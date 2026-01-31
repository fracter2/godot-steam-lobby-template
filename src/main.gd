extends Node2D


const GAME = preload("uid://dx0gencnp27xs")



#
# ---- PROCEDURE ----
#

func _ready() -> void:
	Lobby.connected.connect(_on_connected)										# NOTE Local connected only


#
# ---- SIGNALS ----
#

func _on_connected() -> void:
	#multiplayer.multiplayer_peer = Lobby.multiplayer.multiplayer_peer
	get_tree().change_scene_to_packed(GAME)
