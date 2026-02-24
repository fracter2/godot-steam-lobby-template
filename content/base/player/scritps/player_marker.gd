extends Node2D


func _ready() -> void:
	if is_multiplayer_authority():
		get_tree().create_timer(5).timeout.connect(queue_free)
