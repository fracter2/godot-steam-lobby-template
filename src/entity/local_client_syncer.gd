
# NOTE THIS IS CURRENTLY UNUSED
# TODO DELETE

class_name LocalClientSyncronizer
extends MultiplayerSynchronizer

#@onready var player: Player = $".."
@export var player: PlayerEntity


func _enter_tree() -> void:
	#set_multiplayer_authority(player.peer_id)
	pass

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	pass
