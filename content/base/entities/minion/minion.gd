extends Node2D


@export var speed: float = 80

func _enter_tree() -> void:
	set_multiplayer_authority(get_parent().get_multiplayer_authority())

func _physics_process(delta: float) -> void:
	if is_multiplayer_authority():
		# Movement
		var input_dir: Vector2 = Vector2(Input.get_axis(&"move_left", &"move_right"),  Input.get_axis(&"move_up", &"move_down"))
		position += input_dir * speed * delta
