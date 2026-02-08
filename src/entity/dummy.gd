class_name DummyPlayer
extends Node2D


@export var peer_id: int = 1:
	set(id):
		peer_id = id
		local_client_syncronizer.set_multiplayer_authority(id)
		#print("")

@export var speed: float = 100

@onready var camera_2d: Camera2D = $Camera2D
#@onready var local_client_syncronizer: LocalClientSyncronizer = $LocalClientSyncronizer
@export var local_client_syncronizer: LocalClientSyncronizer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if multiplayer.get_unique_id() == peer_id:
		camera_2d.enabled = true
		camera_2d.make_current()


func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority(): return

	position = local_client_syncronizer.position
