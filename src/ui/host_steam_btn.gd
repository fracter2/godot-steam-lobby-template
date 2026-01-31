extends Button



func _ready() -> void:
	button_down.connect(_on_button_down)




func _process(delta: float) -> void:
	pass


func _on_button_down() -> void:
	Lobby.initiate_lobby(SteamMultiplayerLobby.new(0, true))
