extends Button


func _ready() -> void:
	pressed.connect(_on_btn_pressed)

	if not Steamworks.is_online():
		disabled = true
		tooltip_text = "Cannot host when steam is disabled or inactive!"


func _on_btn_pressed() -> void:
	if not Steamworks.is_online():
		print_debug("Cannot join games when not online!")
		return

	#Steam.activateGameOverlayInviteDialog() TODO Move to a separate button ("Invite Friends") or callback after successfull steam host
	Steam.activateGameOverlay("Friend")
