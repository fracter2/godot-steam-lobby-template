class_name PlayerInfo
extends RefCounted


#
# ---- DATA ----
#

var peer_id: int = 0#:

signal display_name_set(name: StringName)
var display_name: StringName = "":
	get: return display_name
	set(val):
		display_name = val
		display_name_set.emit(val)

signal nickname_set(name: StringName)
var nickname: StringName = "":
	get: return nickname
	set(val):
		nickname = val
		nickname_set.emit(val)

signal steam_id_set(name: int)
var steam_id: int = 0:
	get: return steam_id
	set(val):
		steam_id = val
		steam_id_set.emit(val)

signal avatar_small_set(name: Image)
var avatar_small: Image = null:
	get: return avatar_small
	set(val):
		avatar_small = val
		avatar_small_set.emit(val)

signal avatar_medium_set(name: Image)
var avatar_medium: Image = null:
	get: return avatar_medium
	set(val):
		avatar_medium = val
		avatar_medium_set.emit(val)

signal avatar_large_set(name: Image)
var avatar_large: Image = null:
	get: return avatar_large
	set(val):
		avatar_large = val
		avatar_large_set.emit(val)


#
# ---- PROCEDURE
#

func _init(unique_id: int) -> void:
	peer_id = unique_id
