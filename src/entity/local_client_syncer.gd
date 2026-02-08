class_name LocalClientSyncronizer
extends MultiplayerSynchronizer

#@onready var player: Player = $".."
@export var player: PlayerEntity

@export var position: Vector2 = Vector2.ZERO


func _enter_tree() -> void:
	#set_multiplayer_authority(player.peer_id)
	pass

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if is_multiplayer_authority():
		var input_dir: Vector2 = Vector2(Input.get_axis(&"move_left", &"move_right"),  Input.get_axis(&"move_up", &"move_down"))
		position += input_dir * player.speed * delta
