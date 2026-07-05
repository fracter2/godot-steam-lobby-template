@tool
extends EditorPlugin
## Manages the game-wide lobby connection, along with convenience funcs and PlayerInfo data.
##
## WARNING MAJOR DEPENCY (deleting requires work):
## 			- GodotSteam plugin, for Steam networking features. WORKS FULLY even if Steam is inactive (same as if steam is offline).
##
## WARNING MINOR DEPENCIES (can simply be removed or replaced):
##			- LaunchArgs autoload/plugin, for convenient launch argument parsing.
##			- Log autoload/plugin, as a multi-window aware print() wrapper.


func _enable_plugin() -> void:
	add_autoload_singleton("Lobby", "res://addons/multiplayerlobby/lobby_autoload.gd")


func _disable_plugin() -> void:
	remove_autoload_singleton("Lobby")


func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	pass


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	pass
