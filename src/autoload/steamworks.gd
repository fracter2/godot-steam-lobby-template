extends Node

var steam_enabled: bool = false
var steam_id: int = 0															## Local user steam_id
var persona_name: String = "default_name"

const default_app_id: int = 480 												# NOTE This is SpaceWars.
const app_id: int = default_app_id												# NOTE Replace this when you get your app id!



#
# ---- API ----
#

func is_online() -> bool:
	return steam_enabled and Steam.getPersonaState() != Steam.PERSONA_STATE_OFFLINE



#
# ---- Procedure ----
#

func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = -1														# TODO Consider global constants CONST autoload
	process_physics_priority = -1

func _ready() -> void:
	OS.set_environment("SteamAppID", str(app_id))
	OS.set_environment("SteamGameID", str(app_id))								# TODO Clarify difference between AppID and GameID
	_initialize_steam()
	if steam_enabled:
		steam_id = Steam.getSteamID()
		persona_name = Steam.getPersonaName()


func _process(_d:float) -> void:
	Steam.run_callbacks()


#
# ---- internal logic ----
#

func _initialize_steam() -> void:
	var initialize_response: Dictionary = Steam.steamInitEx(app_id, false)
	print("Did Steam initialize?: %s" % initialize_response)

	if initialize_response['status'] > Steam.STEAM_API_INIT_RESULT_OK:
		push_error("Failed to initialize Steam, shutting down: %s" % initialize_response)
		steam_enabled = false
	else:
		steam_enabled = true
