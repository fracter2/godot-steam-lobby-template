extends Node2D


@export var speed: float = 80


#func _physics_process(delta: float) -> void:
	#if is_multiplayer_authority():
		# Movement

		#position += input_dir * speed * delta
