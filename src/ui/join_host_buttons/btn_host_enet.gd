extends Button



func _ready() -> void:
	button_down.connect(_on_button_down)


func _on_button_down() -> void:
	if Lobby.initiate_lobby(EnetMultiplayerLobby.new(true, "", 8080, "IAmHost")):
		Log.pprint("Successfully initiated EnetMultiplayerLobby")
	else:
		Log.pprint("Failed to initiate EnetMultiplayerLobby")
