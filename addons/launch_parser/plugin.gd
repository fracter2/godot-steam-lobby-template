@tool
extends EditorPlugin

## NOTE YOU MAY WANT TO MOVE THE AUTOLOAD UP IN LOAD PRIORITY, IF OTHER AUTOLOADS DEPEND ON IT ON START

func _enable_plugin() -> void:
	add_autoload_singleton("LaunchArgs", "res://addons/launch_parser/launch_parser.gd")



func _disable_plugin() -> void:
	remove_autoload_singleton("LaunchArgs")
