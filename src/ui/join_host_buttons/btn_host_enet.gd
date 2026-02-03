extends Button



func _ready() -> void:
	button_down.connect(_on_button_down)


func _on_button_down() -> void:
	if Lobby.initiate_lobby(EnetMultiplayerLobby.new(true, "", 8080, "IAmHost")):
		print("Successfully initiated EnetMultiplayerLobby")
	else:
		print("Failed to initiate EnetMultiplayerLobby")
