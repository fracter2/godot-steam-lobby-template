extends Node

var steam_enabled: bool = false

const default_app_id: int = 480 												# NOTE This is SpaceWars.
const app_id: int = default_app_id												# NOTE Replace this when you get your app id!


func _init():
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = -1														# TODO Consider global constants CONST autoload
	process_physics_priority = -1

func _ready():
	OS.set_environment("SteamAppID", str(app_id))
	OS.set_environment("SteamGameID", str(app_id))								# TODO Clarify difference between AppID and GameID

	_print_commandline_args()
	_initialize_steam()


func _process(_d:float) -> void:
	Steam.run_callbacks()


#
# ---- internal logic ----
#

func _print_commandline_args() -> void:
	print("---- command line args ----")
	var cmd_args: Array = OS.get_cmdline_args()
	for argument in cmd_args:
		print(argument)
	print("----\n")
	print("---- command line user args ----")
	var cmd_user_args: Array = OS.get_cmdline_user_args()
	for argument in cmd_user_args:
		print(argument)
	print("----\n")


func _initialize_steam() -> void:
	var initialize_response: Dictionary = Steam.steamInitEx(app_id, false)
	print("Did Steam initialize?: %s" % initialize_response)

	if initialize_response['status'] > Steam.STEAM_API_INIT_RESULT_OK:
		push_error("Failed to initialize Steam, shutting down: %s" % initialize_response)
		steam_enabled = false
	else:
		steam_enabled = true
