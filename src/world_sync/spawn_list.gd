@tool
class_name Spawnlist
extends Resource
## This is meant to serve as a saveable list of node-scene filepaths that MultiplayerSpawner's can add to their spawn list. [br]
## As such it should only contain valid node-scenes. If there are invalid paths, a button will appear that can auto-remove.


## Parses [member list] for invalid file paths
@warning_ignore("unused_private_class_variable")
@export_tool_button("Check Paths") var _check_paths_tool: Callable = _check_invalid_paths

## Export file list got using [method ResourceLoader.get_recognized_extensions_for_type] with [PackedScene] type.
@export_file("*.tscn", "*.res", "*.scn", "*.dae", "*.obj", "*.escn", "*.fbx", "*.gltf", "*.glb", "*.blend", "*.boobs") var list: PackedStringArray:
	set(new_list):
		list = new_list
		_check_invalid_paths()

## The indexes of [member list] that have invalid paths, as decided by [method _is_valid_path].
@export_storage var invalid_path_indexes: PackedInt32Array

## The filetypes that [ResourceLoader] recognizes as [PackedScene]. Got using [method ResourceLoader.get_recognized_extensions_for_type].
const valid_filetypes: PackedStringArray = [".tscn", ".res", ".scn", ".dae", ".obj", ".escn", ".fbx", ".gltf", ".glb", ".blend", ".boobs"]


#
# ---- API ----
#

func get_paths_without_invalid() -> PackedStringArray:
	invalid_path_indexes.sort()
	var clean_list: PackedStringArray = list.duplicate()
	for i: int in range(invalid_path_indexes.size() -1, -1, -1):
		clean_list.remove_at(invalid_path_indexes[i])
	return clean_list


func get_invalid_paths() -> PackedStringArray:
	invalid_path_indexes.sort()
	var invalid_paths: PackedStringArray = []
	for i: int in invalid_path_indexes:
		invalid_paths.push_back(list[i])
	return invalid_paths


#
# ---- Editor Functionality ----
#

func _check_invalid_paths() -> void:
	invalid_path_indexes = _get_invalid_path_indexes(list)
	notify_property_list_changed()	# To reveal / hide the cleanup tool button
	if invalid_path_indexes.is_empty():
		print("Check Paths: All Good!")											# TODO NOTIFY THROUGH TOAST
	else:
		printerr("Check Paths: %d Invalid" % invalid_path_indexes.size())		# TODO NOTIFY THROUGH TOAST


func _remove_invalid() -> void:
	print("Removing invalid indexes...")										# TODO NOTIFY THROUGH TOAST
	if Engine.is_editor_hint():
		var undo_redo: EditorUndoRedoManager = EditorInterface.get_editor_undo_redo()
		undo_redo.create_action("Remove invalid paths from Spawnlist")
		undo_redo.add_do_property(self, &"list", get_paths_without_invalid())
		undo_redo.add_undo_property(self, &"list", list)
		undo_redo.commit_action()
	else:
		list = get_paths_without_invalid()

	notify_property_list_changed()


func _get_property_list() ->  Array[Dictionary]:
	var properties: Array[Dictionary] = []

	if not invalid_path_indexes.is_empty():
		properties.append({
			#"name": "BAD_PATHS(%d/%d)" % [invalid_path_indexes.size(), list.size()],
			"name": "REMOVE_INVALID_PATHS",
			"type": TYPE_CALLABLE,
			"hint": PROPERTY_HINT_TOOL_BUTTON,
			"hint_string": "REMOVE_%d_INVALID_PATHS" % invalid_path_indexes.size()
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
		var p: PackedStringArray = get_invalid_paths()
		for i: int in range(p.size()):
			if ResourceUID.has_id(ResourceUID.text_to_id(p[i])):
				p[i] = ResourceUID.uid_to_path(p[i])
		return p

	else:
		return null


#
# ---- Internal ----
#

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
