class_name Player
extends Node2D


@export var peer_id:int = 1:
	set(id):
		#if not (multiplayer.get_peers().has(id) or id == multiplayer.get_unique_id()):		# NOTE THIS WONT WORK as multiplayer is stored by the scene tree...
		#	print_debug("Tried to set player peer_id using an unknown id!")
		#	return
		peer_id = id
		set_multiplayer_authority(id)
		assert(Lobby.players.has(id))
		player_info = Lobby.players.get(id)
	get():
		return peer_id

@export var speed: float = 120
@export var name_label: Label


var player_info: PlayerInfo = null:
	set(info):
		if player_info != null:
			player_info.display_name_set.disconnect(_update_name)
			player_info.nickname_set.disconnect(_update_name)
		player_info = info
		if player_info != null:
			player_info.display_name_set.connect(_update_name)
			player_info.nickname_set.connect(_update_name)
			_update_name()
	get():
		return player_info



func _ready() -> void:
	if is_multiplayer_authority():
		_spawn_local_camera()


func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority(): return

	var input_dir: Vector2 = Vector2(Input.get_axis(&"move_left", &"move_right"),  Input.get_axis(&"move_up", &"move_down"))
	position += input_dir * speed * delta


func _on_name_set(_new_name: StringName, player: PlayerInfo) -> void:	# TODO REMOVE, Replace with PlayerInfo specific signal callback
	if get_multiplayer_authority() == player.peer_id:
		_update_name()


func _update_name() -> void:
	if not player_info.nickname.is_empty(): 		name_label.text = player_info.nickname
	elif not player_info.display_name.is_empty():	name_label.text = player_info.display_name
	else: 											name_label.text = "DefaultName"



func _spawn_local_camera() -> void:												# TODO Make use of a smart camera system that adapts to available targets
	var cam_node: Camera2D = Camera2D.new()
	cam_node.name = "Local Camera"
	cam_node.enabled = true
	add_child(cam_node, true)
