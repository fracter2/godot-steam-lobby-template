class_name Spawnlist
extends Resource
## This is meant to serve as a saveable list of node-scene filepaths that MultiplayerSpawner's can add to their spawn list. [br]
## As such it can only contain valid node-scenes.



@export_file("*.tscn", "*.scn", "*.boobs") var list: PackedStringArray:
	set(new_list):
		var all_valid: bool = true
		for s:String in new_list:
			if not is_good_path(s):
				all_valid = false
				push_error("Bad Path: " + s)
				break
		if all_valid:
			list = new_list
		else:
			print("Bad list not saved...")



func is_good_path(path: String) -> bool:
	return ResourceLoader.exists(path)
