class_name PlayerCharacter
extends Node2D



@export var speed: float = 100

@export_group("References")
@export var player_entity: PlayerBranch
@export var markers: Node2D
@onready var direction_pointer: Node2D = $Direction

const marker_preload: PackedScene = preload(PATHS.ENTITY_MARKER)

func _physics_process(delta: float) -> void:
	if is_multiplayer_authority():
		# Movement
		var input_dir: Vector2 = Vector2(Input.get_axis(&"move_left", &"move_right"),  Input.get_axis(&"move_up", &"move_down"))
		position += input_dir * speed * delta

		# Marker check
		if Input.is_action_just_pressed(&"spawn_marker"):
			var new_marker : Node2D = marker_preload.instantiate()
			new_marker.position = get_global_mouse_position()
			markers.add_child(new_marker, true)

		# Direction arrow
		direction_pointer.look_at(get_global_mouse_position())
