@tool
class_name Spawnlist
extends Resource
## This is meant to serve as a saveable list of node-scene filepaths that MultiplayerSpawner's can add to their spawn list. [br]
## As such it should only contain valid node-scenes. If there are invalid paths, a button will appear that can auto-remove.


## The filetypes that [ResourceLoader] recognizes as [PackedScene]. Got using [method ResourceLoader.get_recognized_extensions_for_type].
const valid_filetypes: PackedStringArray = [".tscn", ".res", ".scn", ".dae", ".obj", ".escn", ".fbx", ".gltf", ".glb", ".blend", ".boobs"]
const valid_filetypes_combined: String = "*.tscn,*.res,*.scn,*.dae,*.obj,*.escn,*.fbx,*.gltf,*.glb,*.blend,*.boobs"

## Parses [member list] for invalid file paths
@warning_ignore("unused_private_class_variable")
@export_tool_button("Check Paths") var _check_paths_tool: Callable = _check_invalid_paths

@export_storage var uid_paths: Dictionary[int, String]
@export_storage var raw_paths: PackedStringArray
@export_storage var invalid_paths: PackedStringArray
const propertyname_invalid_paths: StringName = &"invalid_paths"


#
# ---- API ----
#

func has_path(path: String) -> bool:
	var uid: int = ResourceUID.text_to_id(path)
	if uid != ResourceUID.INVALID_ID:
		return uid_paths.has(uid)
	else:
		return raw_paths.has(path) or uid_paths.values().has(path)


#
# ---- Editor Functionality ----
#

func _check_invalid_paths() -> void:											# TODO REMAKE WITH UPDATED LOGIC, MAKE REFRESH SETT BY COMIBINING AND SEPPARATING AGAIN
	#invalid_path_indexes = _get_invalid_path_indexes(list)
	notify_property_list_changed()	# To reveal / hide the cleanup tool button
	#if invalid_path_indexes.is_empty():
	#	print("Check Paths: All Good!")
	#else:
	#	printerr("Check Paths: %d Invalid" % invalid_path_indexes.size())


func _remove_invalid() -> void:
	print("Removing invalid indexes...")										# TODO NOTIFY THROUGH TOAST
	if Engine.is_editor_hint():
		var undo_redo: EditorUndoRedoManager = EditorInterface.get_editor_undo_redo()
		undo_redo.create_action("Remove invalid paths from Spawnlist")
		undo_redo.add_do_property(self, propertyname_invalid_paths, [])
		undo_redo.add_undo_property(self, propertyname_invalid_paths, invalid_paths)
		undo_redo.commit_action()
	else:
		invalid_paths.clear()

	notify_property_list_changed()


func _get_property_list() ->  Array[Dictionary]:
	var properties: Array[Dictionary] = []

	properties.append({
			"name": "SCENE_PATHS",
			"type": TYPE_PACKED_STRING_ARRAY,
			"hint": PROPERTY_HINT_FILE,
			"hint_string": "%d/%d:%s" % [TYPE_STRING, PROPERTY_HINT_FILE, valid_filetypes_combined]
		})

	if not invalid_paths.is_empty():
		properties.append({
			#"name": "BAD_PATHS(%d/%d)" % [invalid_path_indexes.size(), list.size()],
			"name": "REMOVE_INVALID_PATHS",
			"type": TYPE_CALLABLE,
			"hint": PROPERTY_HINT_TOOL_BUTTON,
			"hint_string": "REMOVE_%d_INVALID_PATHS" % invalid_paths.size()
		})
		properties.append({
			"name": "BAD_PATHS",
			"type": TYPE_PACKED_STRING_ARRAY,
			"hint": PROPERTY_HINT_FILE,
			"hint_string": "String"
		})


	return properties


func _get(property: StringName) -> Variant:
	if property == &"REMOVE_INVALID_PATHS":
		return _remove_invalid

	elif property == &"BAD_PATHS":
		var p: PackedStringArray = invalid_paths
		for i: int in range(p.size()):
			if ResourceUID.has_id(ResourceUID.text_to_id(p[i])):
				p[i] = ResourceUID.uid_to_path(p[i])
		return p

	elif property == &"SCENE_PATHS":
		var p: PackedStringArray = _get_all_paths()
		return p

	else:
		return null


func _set(property: StringName, value: Variant) -> bool:

	if property == &"SCENE_PATHS" and value is PackedStringArray:
		_parse_new_list(value as PackedStringArray)
		return true

	return false


#
# ---- Internal ----
#

func _parse_new_list(paths: PackedStringArray) -> void:
	uid_paths.clear()
	raw_paths.clear()
	invalid_paths.clear()

	for s: String in paths:
		if _is_valid_path(s):
			var uid: int = ResourceUID.text_to_id(s)
			if ResourceUID.has_id(uid):
				uid_paths.set(uid, ResourceUID.get_id_path(uid))
			else:
				raw_paths.push_back(s)
		else:
			invalid_paths.push_back(s)

	notify_property_list_changed()	# To reveal / hide the cleanup tool button
	if invalid_paths.is_empty():
		print("Check Paths: All Good!")
		EditorInterface.get_editor_toaster().push_toast("SpawnList Successfully Set!")
	else:
		printerr("Check Paths: %d Invalid" % invalid_paths.size())
		EditorInterface.get_editor_toaster().push_toast("Check Paths: %d Invalid" % invalid_paths.size(), EditorToaster.SEVERITY_ERROR, "You prob input an empty path or misspelled one")


func _get_all_paths() -> PackedStringArray:
	var r: PackedStringArray = []
	for i: int in uid_paths.keys():
		r.push_back(ResourceUID.id_to_text(i))
	r.append_array(raw_paths)
	r.append_array(invalid_paths)
	return r


func _get_invalid_path_indexes(paths: PackedStringArray) -> PackedInt32Array:
	var r: PackedInt32Array = []
	for i: int in range(0, paths.size()):
		if not _is_valid_path(paths[i]):
			r.push_back(i)
	return r


func _is_valid_path(path: String) -> bool:
	return (not path.is_empty()) and ResourceLoader.exists(path, "PackedScene") and _ends_with_valid_filetype(path)


func _ends_with_valid_filetype(path: String) -> bool:
	if ResourceUID.has_id(ResourceUID.text_to_id(path)):
		path = ResourceUID.uid_to_path(path)

	for type:String in valid_filetypes:
		if path.ends_with(type):
			return true
	return false
