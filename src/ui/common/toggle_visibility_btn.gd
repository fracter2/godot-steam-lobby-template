extends Button

@export var target: CanvasItem


func _ready() -> void:
	pressed.connect(toggle_vis)


func toggle_vis() -> void:
	if target:
		target.visible = not target.visible
