extends Button


@export var ip_textbox: LineEdit
@export var port_textbox: LineEdit
@export var name_textbox: LineEdit

func _ready() -> void:
	button_down.connect(_on_button_down)
	if ip_textbox == null or port_textbox == null or name_textbox == null:
		disabled = true
		tooltip_text += "\nDISABLED: Not configured correctly!"

	# TODO MAKE WARNING APPEAR AND DISABLE WHEN INPUT PARAMETERS ARE BAD!


func _on_button_down() -> void:

	var ishost: bool = false
	var ip: String = ip_textbox.text
	var port: int = port_textbox.text.to_int()
	var username: String = name_textbox.text

	if not ip.is_valid_ip_address(): return
	#if not port # TODO VALIDATE PORT


	var lobby: EnetMultiplayerLobby = EnetMultiplayerLobby.new(ishost, ip, port, username)
	if not Lobby.initiate_lobby(lobby):
		print("join enet btn attempt got aborted (figure out why yourself. bad args?)")
