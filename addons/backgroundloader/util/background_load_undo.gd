class_name BackgroundLoadUndo ## Unloads scene by path from the BackgroundLoader
extends Node


@export_file() var next_level: String											# TODO ALLOW MULTIPLE as an array
@export var on_enter: bool = false
@export var on_exit: bool = true



func _enter_tree() -> void:
	if on_enter: BackgroundLoader.undo_prepare(next_level)


func _exit_tree() -> void:
	if on_exit: BackgroundLoader.undo_prepare(next_level)
