class_name PlayerCharacter
extends Node2D



@export var speed: float = 100

@export_group("References")
@export var player_entity: PlayerEntity

#var player_info: PlayerInfo


func _physics_process(delta: float) -> void:
	if is_multiplayer_authority():
		var input_dir: Vector2 = Vector2(Input.get_axis(&"move_left", &"move_right"),  Input.get_axis(&"move_up", &"move_down"))
		position += input_dir * speed * delta
