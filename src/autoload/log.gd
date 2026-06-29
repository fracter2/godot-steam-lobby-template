extends Node

## The purpose of this is to provide a simple logg wrapper to help with local debugging using multiple running instances.

@export var add_color_as_prefix: bool = true
@export var add_color_to_window_title: bool = true

var color: Color = Color.WHITE
var color_bb: String = "[color=WHITE]"
const color_bb_end: String = "[/color]"

var prefix: String = ""


func _enter_tree() -> void:
	if not LaunchArgs.has_command("-logcolor"): return

	var values: PackedStringArray = LaunchArgs.get_values("-logcolor")
	if values.is_empty():
		push_warning("Launch command -logcolor was not given a value. Don't forget to add a named color or color hex like -logcolor=colorhere")
		return

	var launch_color_name: String = values[0]			# NOTE THERE SHOULD BE EXACLY ONE VALUE
	var launch_color: Color = Color.from_string(launch_color_name, Color.TRANSPARENT)
	if launch_color == Color.TRANSPARENT:
		push_warning("Launch argument -logcolor was not given a valid color (or was given Color.TRANSPARENT). value: %s" % launch_color_name)
		return

	color_bb = "[color=%s]" % launch_color_name
	color = launch_color
	if add_color_as_prefix:
		prefix = launch_color_name + ": "
		# TODO CONSIDER SETTING SPECIFIC LENGTH using spaces before/after
	pprint("Log: color set")

	if add_color_to_window_title:
		get_window().title = prefix + get_window().title


func _notification(what: int) -> void:
	if what == NOTIFICATION_CRASH:
		pprint("Log: just crashed lol")
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		pprint("Log: window close requested")


## Returns the values converted to string, with the color bb wrapped at the start and end. [br]
## Same conversion as [method pprint].
func pwrap(txt: String) -> String:
	return (color_bb + prefix + txt + color_bb_end)


## Prints text with color using print_rich().
func pprint(txt: String) -> void:												# TODO RENAME TO info
	print_rich(color_bb + prefix + txt + color_bb_end)
