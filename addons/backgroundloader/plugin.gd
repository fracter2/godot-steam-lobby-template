@tool
extends EditorPlugin


func _enable_plugin() -> void:
	add_autoload_singleton("BackgroundLoader", "res://addons/backgroundloader/background_loader.gd")


func _disable_plugin() -> void:
	remove_autoload_singleton("BackgroundLoader")
