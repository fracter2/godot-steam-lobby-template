extends Node
## Convenience GodotSteam wrapper that initializes the app propperly, stores common values (like steam_enabled or player's steam_id), and keeps control of Steam callback cycle.


const default_app_id: int = 480 												# NOTE This is SpaceWars.

var steam_enabled: bool = false:
	set(value):
		if is_node_ready():
			push_error("Steamworks.steam_enabled cannot be set after _enter_tree()! Because why would you??")
			breakpoint
		else:
			steam_enabled = value

var steam_id: int = 0															## Local user steam_id
var app_id: int = default_app_id:
	set(new_id):
		app_id = new_id if new_id > 0 else default_app_id

var persona_name: String = "default_name"

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
	process_priority = -1
	process_physics_priority = -1


func _enter_tree() -> void:
	if LaunchArgs.has_command("--no-steam"):									# TODO TRY MAKING INDEPENDENT FROM LaunchArgs
		Log.pprint("Launch arg no-steam set. Skipping Steamworks init.")		# TODO MAKE INDEPENDENT FROM Log.pprint
		return

	OS.set_environment("SteamAppID", str(app_id))
	OS.set_environment("SteamGameID", str(app_id))								# TODO Clarify difference between AppID and GameID

	_initialize_steam()
	if steam_enabled:
		steam_id = Steam.getSteamID()
		persona_name = Steam.getPersonaName()


func _process(_d:float) -> void:												# TODO MOVE TO get_tree().process.connect()
	if steam_enabled:
		Steam.run_callbacks()


#
# ---- internal logic ----
#

func _initialize_steam() -> void:
	var initialize_response: Dictionary = Steam.steamInitEx(app_id, false)
	Log.pprint("Did Steam initialize?: %s" % initialize_response)

	if initialize_response['status'] > Steam.STEAM_API_INIT_RESULT_OK:
		push_error("Failed to initialize Steam, shutting down: %s" % initialize_response)
		steam_enabled = false
	else:
		steam_enabled = true
