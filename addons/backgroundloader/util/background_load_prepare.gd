class_name BackgroundLoadPrepare	## Loads scene in the background using BackgroundLoader
extends Node

@export_file() var scene: String												# TODO ALLOW MULTIPLE as an array
@export var keep_after_exit: bool = false


func _enter_tree() -> void:
	BackgroundLoader.prepare(scene, true, keep_after_exit)
