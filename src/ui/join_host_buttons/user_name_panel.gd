extends HBoxContainer

@export var read_cmdline_enet_username: bool = true
@export var remember_in_settings: bool = true

@onready var label: Label = %Label
@onready var line_edit: LineEdit = %LineEdit

const default_username: String = "Defaultus"

func get_username() -> String:
	# TODO REMOVE INVALID CHARACTERS
	# TODO PROFANITY FILTER?
	# TODO WARNING_ICON WHEN INVALID
	# TODO RETURN DEFAULT USERNAME IF NOTHING ELSE
	var username: String = line_edit.text
	if username.is_empty():
		username = default_username

	return line_edit.text


func is_valid_username() -> bool:
	# TODO
	return true
