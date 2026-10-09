@tool
extends EditorPlugin

## NOTE YOU MAY WANT TO MOVE THE AUTOLOAD UP IN LOAD PRIORITY, IF OTHER AUTOLOADS DEPEND ON IT ON START

# TODO FIX NAME: EITHER LaunchParser OR LaunchArgs

func _enable_plugin() -> void:
	add_autoload_singleton("LaunchArgs", "res://addons/launch_parser/launch_parser.gd")

func _disable_plugin() -> void:
	remove_autoload_singleton("LaunchArgs")


#func _collect_used_launch_args() -> PackedStringArray:

	# TODO Serach files
	# TODO Filter using folder / extension / regex, in project settings

	# TODO find each LaunchArgs.has_command(key)
	# TODO find each LaunchArgs.get_values(key)
	# TODO List each with what key was used, sanitized + original in ()
	# such as LaunchArgs.has_command("-winpos") -> "--winpos (-winpos)"

	# TODO find each OS.get_cmdline_args() and OS.get_cmdline_user_args()
	# TODO list them separately, but remember which file and line
	# TODO IF not too much, add what string was searched for.

	# TODO Finally, output into a .txt of the project-settings choosing (default res://launch_args_available.txt)
	# TODO Optionally, allow it to be a class file that is added, with each command with it's own const.
