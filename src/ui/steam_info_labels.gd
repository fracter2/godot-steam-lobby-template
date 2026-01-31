extends Control

@export var steam_status: Label


func _ready() -> void:
	if Steamworks.enabled:
		steam_status.text = ("Connected to Steam as %s %s" %
			[Steam.getPersonaName(),
			"(online)" if Steamworks.is_online() else "(offline)"])

	else:
		steam_status.text = "Failed to connect to Steam!"
