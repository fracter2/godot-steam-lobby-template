extends Panel

@onready var button: Button = $Button
@onready var label: Label = $Label

const MAIN_SCENE_PATH = "res://src/Main.tscn"

func _ready() -> void:
	button.pressed.connect(_on_main_menu_pressed)


func _on_main_menu_pressed() -> void:
	# NOTE DON'T SWAP SCENES HERE. let Lobby.leave_lobby() handle it. To avoid breaking Node.multiplayer property such before lobby quit.
	Lobby.leave_lobby("Returning to main menu")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		visible = not visible
