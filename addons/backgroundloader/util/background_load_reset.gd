class_name BackgroundLoadReset	## Resets the BackgroundLoaders kept file paths
extends Node

@export var on_enter: bool = true
@export var on_exit: bool = false

func _enter_tree() -> void:
	if on_enter: BackgroundLoader.reset()


func _exit_tree() -> void:
	if on_exit: BackgroundLoader.reset()
