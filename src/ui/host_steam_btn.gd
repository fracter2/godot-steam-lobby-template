extends Button



func _ready() -> void:
	button_down.connect(_on_button_down)

	if not Steamworks.is_online():
		disabled = true
		tooltip_text = "Cannot host when steam is disabled or inactive!"



func _on_button_down() -> void:
	if Lobby.initiate_lobby(SteamMultiplayerLobby.new(0, true)):
		print("Successfully initiated SteamMultiplayerLobby")
	else:
		print("Failed to initiate SteamMultiplayerLobby")
