extends Panel

@onready var button: Button = $Button
@onready var label: Label = $Label

const MAIN = preload("uid://bp3lhs80g85ky")


func _ready() -> void:
	button.pressed.connect(_on_main_menu_pressed)


func _on_main_menu_pressed() -> void:
	get_tree().change_scene_to_packed(MAIN)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		visible = not visible
