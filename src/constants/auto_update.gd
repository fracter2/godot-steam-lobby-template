@tool
extends EditorScript



const autogen_disclaimer: String = "\n# Dis scrip is audogenewaded by auto_update tool button\n"
const prefix_const: String = "\nconst "
const prefix_stringname: String = ": StringName = &\""
const prefix_int: String = ": int = "
const suffix_endquotes: String = "\""


#
# ---- Editor ----
#

func _run() -> void:
	print("")	# Line separator for visual clarity
	_print_and_toast("auto_update.gd: updating LAYERS...")
	_update_layers()
	_print_and_toast("auto_update.gd: updating GROUPS...")
	_update_groups()
	_print_and_toast("auto_update.gd: validating PATHS")
	_validate_paths()
	_print_and_toast("auto_update.gd: Done!")


func _print_and_toast(txt: String, severity: int = EditorToaster.SEVERITY_INFO, desc: String = "Hi i'm a toaster!") -> void:
	EditorInterface.get_editor_toaster().push_toast(txt, severity, desc)
	if severity == EditorToaster.SEVERITY_ERROR:
		printerr(txt)
	else:
		print(txt)


#
# ---- Helper ----
#

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


#§
# ---- LAYERS SCRIPT ----
#

const layers_script_header_: String = "class_name LAYERS
extends Object

## This class serves to list all LAYERS used in this project.
## To make them strongly typed, StringName cached, and enable text auto-completion.
"

func _update_layers() -> void:
	if not Engine.is_editor_hint(): return

	var named_layers: Dictionary[String, int] = _get_all_named_layers()
	var new_script: String = layers_script_header_ + autogen_disclaimer
	for l_name: String in named_layers.keys():
		new_script += prefix_const
		new_script += (l_name.to_snake_case()).to_upper()
		new_script += prefix_int
		new_script += str(named_layers[l_name])

	if _replace_text_in_file(new_script, PATHS.SCRIPT_LAYERS):
		EditorInterface.get_resource_filesystem().update_file(PATHS.SCRIPT_LAYERS)
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

const groups_script_header_: String = "class_name GROUPS
extends Object

## This class serves to list all GROUPS used in this project.
## To make them strongly typed, StringName cached, and enable text auto-completion.
"

func _update_groups() -> void:
	if not Engine.is_editor_hint(): return

	var groups: Array[String] = _get_all_groups()
	var new_script: String = groups_script_header_ + autogen_disclaimer
	for gname: String in groups:
		new_script += prefix_const
		new_script += (gname.to_snake_case()).to_upper()
		new_script += prefix_stringname
		new_script += gname
		new_script += suffix_endquotes

	if _replace_text_in_file(new_script, PATHS.SCRIPT_GROUPS):
		EditorInterface.get_resource_filesystem().update_file(PATHS.SCRIPT_GROUPS)
		EditorInterface.get_script_editor().reload_open_files()
		EditorInterface.get_editor_toaster().push_toast("Successfully updated PATHS.SCRIPT_GROUPS! yay!", EditorToaster.SEVERITY_INFO, "Hi i'm a toaster!")
	else:
		push_error("_update_groups func failed to write to file!")
		EditorInterface.get_editor_toaster().push_toast("Failed to update PATHS.SCRIPT_GROUPS :(", EditorToaster.SEVERITY_ERROR, "Hi i'm a toaster!")


func _get_all_groups() -> Array[String]:
	var timer_start: int = Time.get_ticks_usec()
	var check_counter: int = 0
	var property_list := ProjectSettings.get_property_list()
	var ret: Array[String] = []
	for prop: Dictionary in property_list:
		if (prop["name"] as String).begins_with("global_group/"):
			ret.push_back((prop["name"] as String).trim_prefix("global_group/"))
		check_counter += 1

	print("auto_update.gd _update_groups() took %d usec, with %d groups found, %d total settings checked" % [(Time.get_ticks_usec() - timer_start), ret.size(), check_counter])
	return ret


#
# ---- PATHS SCRIPT ----
#

func _validate_paths() -> void:
	var timer_start: int = Time.get_ticks_usec()

	var p: PATHS = PATHS.new()
	var script: Script = p.get_script()
	p.free()
	if not script:
		EditorInterface.get_editor_toaster().push_toast("PATHS VALIDATION FUNC BROKEN!!", EditorToaster.SEVERITY_INFO, "Hi i'm a toaster!")
		printerr("PATHS VALIDATION FUNC BROKEN!!")
		return

	var good_consts: int = 0
	var bad_consts: int = 0
	var constants: Dictionary = script.get_script_constant_map()
	for key: Variant in constants.keys():
		var val: Variant = constants[key]
		var err_msg: String = ""
		if not val is String:
			err_msg = "PATHS.%s has invalid type! value: %s" % [key, str(val)]
		elif val == null:
			err_msg = "PATHS.%s has null value!" % [key]
			@warning_ignore("unsafe_call_argument")
		elif not ResourceLoader.exists((val)):
			#push_error("PATHS const has invalid path! value: " + val)
			err_msg = "PATHS.%s has invalid path! path: %s" % [key, str(val)]

		if err_msg:
			bad_consts += 1
			printerr(err_msg)
			EditorInterface.get_editor_toaster().push_toast(err_msg, EditorToaster.SEVERITY_INFO, "Hi i'm a toaster!")
		else:
			good_consts += 1

	print("validate_paths() finished after %d usec, with %d good / %d bad consts" % [(Time.get_ticks_usec() - timer_start), good_consts, bad_consts])

#
# ---- META SCRIPT ----
#

# TODO auto-update or verify
