class_name PlayerCharacter
extends Node2D


const marker_preload: PackedScene = preload(PATHS.ENTITY_MARKER)

@export var speed: float = 100

@export_group("References")
@export var camera_2d: Camera2D
@export var name_label: Label
@onready var direction_pointer: Node2D = $Direction


var player_spawner: ClientSpawner = null:
	set(new_spawner):
		player_spawner = new_spawner
		player_info = new_spawner.player_info

var player_info: PlayerInfo = null:
	set(info):
		_disconnect_player_info(player_info)
		player_info = info
		_connect_player_info(info)

#
# ---- Procedure ----
#

func _enter_tree() -> void:
	player_spawner = ClientSpawnManager.get_spawner_of(self)
	assert(player_spawner != null )


func _ready() -> void:
	if player_spawner.peer_id != get_multiplayer_authority():
		push_error("PlayerCharacter authority not set correctly!")
		return

	player_info = Lobby.players[get_multiplayer_authority()]
	if is_multiplayer_authority():
		camera_2d.enabled = true
		camera_2d.make_current()


func _physics_process(delta: float) -> void:
	if is_multiplayer_authority():
		# Movement
		var input_dir: Vector2 = Vector2(Input.get_axis(&"move_left", &"move_right"),  Input.get_axis(&"move_up", &"move_down"))
		position += input_dir * speed * delta

		# Marker check
		if Input.is_action_just_pressed(&"spawn_marker"):
			var new_marker : Node2D = marker_preload.instantiate()
			new_marker.position = get_global_mouse_position()

			player_spawner.spawn_node(new_marker)

		# Direction arrow
		direction_pointer.look_at(get_global_mouse_position())


#
# ---- SIGNAL CALLBACKS ----
#

func _on_name_set(_new_name: String = "") -> void:
	if not player_info.nickname.is_empty(): 		name_label.text = player_info.nickname
	elif not player_info.display_name.is_empty():	name_label.text = player_info.display_name
	else: 											name_label.text = "DefaultName"


func _on_avatar_set(_new_avatar: Image = null) -> void:
	if not player_info.avatar_small == null:
		# TODO SET AVATAR PIC
		pass

#
# ---- INTERNALS ----
#

func _disconnect_player_info(player: PlayerInfo) -> void:
	if player != null:
		player.display_name_set.disconnect(_on_name_set)
		player.nickname_set.disconnect(_on_name_set)
		player.avatar_small_set.disconnect(_on_avatar_set)


func _connect_player_info(player: PlayerInfo) -> void:
	if player != null:
		player.display_name_set.connect(_on_name_set)
		player.nickname_set.connect(_on_name_set)
		_on_name_set()
		player.avatar_small_set.connect(_on_avatar_set)
		_on_avatar_set()
