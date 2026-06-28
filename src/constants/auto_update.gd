@tool
extends EditorScript



const autogen_disclaimer: String = "\n# Dis scrip is audogenewaded by auto_update tool button\n"
const prefix_const: String = "\nconst "
const type_stringname: String = ": StringName = &\""
const type_int: String = ": int = "
const suffix_endquotes: String = "\""

#
# ---- Common funcs ----
#

func _run() -> void:
	var toaster := EditorInterface.get_editor_toaster()
	toaster.push_toast("auto_update.gd updating LAYERS...", EditorToaster.SEVERITY_INFO, "Hi i'm a toaster!")
	_update_layers()
	toaster.push_toast("auto_update.gd Done!", EditorToaster.SEVERITY_INFO, "Hi i'm a toaster!")


func _replace_text_in_file(text: String, filepath: String) -> bool:
	if not FileAccess.file_exists(filepath):
		push_error("file not found! At " + filepath)
		return false

	var file: FileAccess = FileAccess.open(filepath, FileAccess.WRITE)
	if not file.resize(0) == Error.OK:
		push_error("file.resize(0) failed! At :" + filepath)
		return false

	if not file.store_string(text):
		push_error("FileAccess.store_string() failed! At :" + filepath)
		return false

	file.close()
	return true


#
# ---- LAYERS SCRIPT ----
#

const layers_script_header_: String = "class_name LAYERS
extends Object

## This class serves to list all LAYERS used in this project.
## To make them strongly typed, StringName cached, and enable text auto-completion.
"

func _update_layers() -> void:
	if not Engine.is_editor_hint(): return
	print("Updating Layers in " + PATHS.SCRIPT_LAYERS)

	var named_layers: Dictionary[String, int] = _get_all_named_layers()
	var new_script: String = layers_script_header_ + autogen_disclaimer
	for l_name: String in named_layers.keys():
		new_script += prefix_const
		new_script += (l_name.to_snake_case()).to_upper()
		new_script += type_int
		new_script += str(named_layers[l_name])

	if _replace_text_in_file(new_script, PATHS.SCRIPT_LAYERS):
		EditorInterface.get_resource_filesystem().update_file(PATHS.SCRIPT_LAYERS)
		#EditorInterface.get_resource_filesystem().scan()
		EditorInterface.get_script_editor().reload_open_files()
		EditorInterface.get_editor_toaster().push_toast("Successfully updated PATHS.SCRIPT_LAYERS! yay!", EditorToaster.SEVERITY_INFO, "Hi i'm a toaster!")
	else:
		push_error("_update_layers func failed to write to file!")
		EditorInterface.get_editor_toaster().push_toast("Failed to update PATHS.SCRIPT_LAYERS :(", EditorToaster.SEVERITY_ERROR, "Hi i'm a toaster!")


func _get_all_named_layers() -> Dictionary[String, int]:
	var resulting_constants: Dictionary[String, int] = {}
	resulting_constants.merge(_get_named_layers_group("2d_render", "rend2d_", 20))
	resulting_constants.merge(_get_named_layers_group("2d_physics", "phys2d_", 32))
	resulting_constants.merge(_get_named_layers_group("2d_navigation", "nav2d_", 32))
	resulting_constants.merge(_get_named_layers_group("3d_render", "rend3d_", 20))
	resulting_constants.merge(_get_named_layers_group("3d_physics", "phys3d_", 32))
	resulting_constants.merge(_get_named_layers_group("3d_navigation", "nav3d_", 32))
	resulting_constants.merge(_get_named_layers_group("avoidance", "av_", 32))
	return resulting_constants


func _get_named_layers_group(group: String, name_pref: String, max_layer: int) -> Dictionary[String, int]:
	var resulting_constants: Dictionary[String, int] = {}
	for i: int in range(1, max_layer + 1):
		var layer_name: String = ProjectSettings.get_setting("layer_names/" + group + "/layer_" + str(i))
		if layer_name != null and not layer_name.is_empty():
			resulting_constants.set(name_pref + layer_name, i)
	return resulting_constants


#
# ---- GROUPS SCRIPT ----
#

# TODO auto-update

#
# ---- PATHS SCRIPT ----
#

# TODO Validation (NOT UPDATE)

#
# ---- META SCRIPT ----
#

# TODO auto-update
