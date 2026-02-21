extends Node

const screen_margin: Vector2i = Vector2i(32, 32)	## Offset from top-left corner of the screen

func _enter_tree() -> void:
	if LaunchArgs.has_command("-winpos-tile"):
		_parse_multi_window()

	elif LaunchArgs.has_command("-winpos"):
		_parse_winpos()

	# TODO LET LAUNCH COMMAND SET WINDOW POSITION THROUGH COORDINATES OR THROUGH UV (0-1 decimal
	print("Window position set to: " + str(get_window().position))


func _parse_multi_window() -> void:
	var values: PackedStringArray = LaunchArgs.get_values("-winpos-tile")
	if values.size() < 1:
		push_warning("window_spawn_aligner -winpos-tile: AINT ENOUGH ARGS. Shoyuld be -winpos-tile=index")
		return

	var offset: Vector2i = screen_margin
	var window_size: Vector2i = get_window().size
	var index: int = clampi(values[0].to_int(), 0, 100)							# NOTE index 0 is min, arbituary max
	@warning_ignore("integer_division") var row_capacity: int = (DisplayServer.screen_get_size().x - 2 * screen_margin.x) / (window_size.x)
	@warning_ignore("integer_division") offset.x += window_size.x * (index % row_capacity)
	@warning_ignore("integer_division") offset.y += window_size.y * (index / row_capacity)

	get_window().initial_position = Window.WINDOW_INITIAL_POSITION_ABSOLUTE		# NOTE To allow setting pos
	get_window().position = offset + DisplayServer.screen_get_position()



func _parse_winpos() -> void:
	var values: PackedStringArray = LaunchArgs.get_values("-winpos")
	if values.size() < 2:
		push_warning("window_spawn_aligner -winpos: AINT ENOUGH ARGS. Should be -winpos=x=y=screenindex. screenindex -1 for main, -2 for primary, -3 for keyboard focus, -4 for mouse focus, or 0, 1, 2...")
		return

	var ax: int = values[0].to_int()
	var ay: int = values[1].to_int()
	var monitor_index: int = -1
	if values.size() > 2:
		monitor_index = values[2].to_int()
		monitor_index = clampi(monitor_index, -4, DisplayServer.get_screen_count() - 1)

	get_window().position = Vector2i(ax, ay) + DisplayServer.screen_get_position(monitor_index)
