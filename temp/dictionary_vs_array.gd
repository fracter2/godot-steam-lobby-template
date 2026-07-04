@tool
extends EditorScript

#
# ---- Procedure ----
#

func _run() -> void:
	print("\n")
	test_case_find_existing()
	print("")
	test_case_find_existing_int()
	print("")
	test_case_uid_conversion()
	print("")


#
# ---- Timer stuff
#

var timer_test_name: String = "Test: "
var timer_starttick_usec: int = 0


func _timer_start(new_test_name: String) -> void:
	timer_test_name = new_test_name
	timer_starttick_usec = Time.get_ticks_usec()


func _timer_stop() -> int:
	var time_usec: int = Time.get_ticks_usec() - timer_starttick_usec
	print("- %d usec - %s" % [time_usec, timer_test_name])
	return time_usec


func _timer_stop_start(new_test_name: String) -> int:
	var t_usec: int = _timer_stop()
	_timer_start(new_test_name)
	return t_usec


#
# ---- Tests ----
#



func test_case_find_existing() -> void:
	print("---- test_case_find_existing ----")
	var string_arr: Array[String] = []
	var string_packed_arr: PackedStringArray = []
	var string_packed_arr_sorted: PackedStringArray = []
	var string_dict: Dictionary[String, int] = {}
	var names: PackedStringArray = []

	for i: int in range(1000, 3000): names.push_back("a" + str(i))

	_timer_start("string_arr.push_back")
	for i: int in range(1000): string_arr.push_back(names[i])
	_timer_stop_start("string_packed_arr.push_back")
	for i: int in range(1000):  string_packed_arr.push_back(names[i])
	_timer_stop_start("string_packed_arr_sorted.push_back")
	for i: int in range(1000):  string_packed_arr_sorted.push_back(names[i])
	_timer_stop_start("string_dict.set")
	for i: int in range(1000):  string_dict.set(names[i], i)

	_timer_stop_start("string_packed_arr_sorted.sort()")
	string_packed_arr_sorted.sort()

	_timer_stop_start("string_packed_arr_sorted.reverse()")
	string_packed_arr_sorted.reverse()

	_timer_stop_start("string_packed_arr_sorted.sort() (after reverse)")
	string_packed_arr_sorted.sort()

	_timer_stop_start("combining strings 1000 times")
	for i: int in range(1000, 2000):
		"a" + str(i)

	_timer_stop_start("string_arr.has (exists)")
	for i: int in range(1000): string_arr.has(names[i])
	_timer_stop_start("string_arr.has (not exists)")
	for i: int in range(1000, 2000): string_arr.has(names[i])

	_timer_stop_start("string_packed_arr.has (exists)")
	for i: int in range(1000): string_packed_arr.has(names[i])
	_timer_stop_start("string_packed_arr.has (not exists)")
	for i: int in range(1000, 2000): string_packed_arr.has(names[i])

	_timer_stop_start("string_packed_arr_sorted.has (exists)")
	for i: int in range(1000): string_packed_arr_sorted.has(names[i])
	_timer_stop_start("string_packed_arr_sorted.has (not exists)")
	for i: int in range(1000, 2000): string_packed_arr_sorted.has(names[i])

	_timer_stop_start("string_packed_arr_sorted.bsearch(exists)")
	for i: int in range(1000):
		var index: int = string_packed_arr_sorted.bsearch(names[i])
		index < string_packed_arr_sorted.size() and string_packed_arr_sorted[index] == names[i]
	_timer_stop_start("string_packed_arr_sorted.bsearch (not exists)")
	for i: int in range(1000, 2000):
		var index: int = string_packed_arr_sorted.bsearch(names[i])
		index < string_packed_arr_sorted.size() and string_packed_arr_sorted[index] == names[i]

	_timer_stop_start("string_dict.has (exists)")
	for i: int in range(1000): string_dict.has(names[i])
	_timer_stop_start("string_dict.has (not exists)")
	for i: int in range(1000, 2000): string_dict.has(names[i])
	_timer_stop()




func test_case_find_existing_int() -> void:
	print("---- test_case_find_existing_int ----")
	var int_arr: Array[int] = []
	var int_packed_arr: PackedInt64Array = []
	var int_packed_arr_sorted: PackedInt64Array = []
	var int_dict: Dictionary[int, String] = {}
	var names: PackedInt64Array = []

	for i: int in range(1000, 3000): names.push_back(i)

	_timer_start("int_arr.push_back")
	for i: int in range(1000): int_arr.push_back(names[i])
	_timer_stop_start("int_packed_arr.push_back")
	for i: int in range(1000):  int_packed_arr.push_back(names[i])
	_timer_stop_start("int_packed_arr_sorted.push_back")
	for i: int in range(1000):  int_packed_arr_sorted.push_back(names[i])
	_timer_stop_start("int_dict.set")
	for i: int in range(1000):  int_dict.set(names[i], str(i))

	_timer_stop_start("int_packed_arr_sorted.sort()")
	int_packed_arr_sorted.sort()

	_timer_stop_start("int_packed_arr_sorted.reverse()")
	int_packed_arr_sorted.reverse()

	_timer_stop_start("int_packed_arr_sorted.sort() (after reverse)")
	int_packed_arr_sorted.sort()

	_timer_stop_start("int_arr.has (exists)")
	for i: int in range(1000): int_arr.has(names[i])
	_timer_stop_start("int_arr.has (not exists)")
	for i: int in range(1000, 2000): int_arr.has(names[i])

	_timer_stop_start("int_packed_arr.has (exists)")
	for i: int in range(1000): int_packed_arr.has(names[i])
	_timer_stop_start("int_packed_arr.has (not exists)")
	for i: int in range(1000, 2000): int_packed_arr.has(names[i])

	_timer_stop_start("int_packed_arr_sorted.has (exists)")
	for i: int in range(1000): int_packed_arr_sorted.has(names[i])
	_timer_stop_start("int_packed_arr_sorted.has (not exists)")
	for i: int in range(1000, 2000): int_packed_arr_sorted.has(names[i])

	_timer_stop_start("int_packed_arr_sorted.bsearch(exists)")
	for i: int in range(1000):
		var index: int = int_packed_arr_sorted.bsearch(names[i])
		index < int_packed_arr_sorted.size() and int_packed_arr_sorted[index] == names[i]
	_timer_stop_start("int_packed_arr_sorted.bsearch (not exists)")
	for i: int in range(1000, 2000):
		var index: int = int_packed_arr_sorted.bsearch(names[i])
		index < int_packed_arr_sorted.size() and int_packed_arr_sorted[index] == names[i]

	_timer_stop_start("int_dict.has (exists)")
	for i: int in range(1000): int_dict.has(names[i])
	_timer_stop_start("int_dict.has (not exists)")
	for i: int in range(1000, 2000): int_dict.has(names[i])
	_timer_stop()



func test_case_uid_conversion() -> void:
	print("---- test_case_uid_conversion ----")
	var int_names: PackedInt64Array = []
	var str_names: PackedStringArray = []
	var str_uids: PackedStringArray = []
	var existing_uid: String = "uid://3e7do5gg31dg"
	for i: int in range(1000, 3000): str_names.push_back("aaaaaaaaaaaaaaaaaaaa" + str(i))
	for i: int in range(1000, 3000): str_uids.push_back("uid://" + str(i))
	for i: int in range(1000, 3000): int_names.push_back(i)

	_timer_start("ResourceUID.path_to_uid() (bad)")
	for i: int in range(1000): ResourceUID.path_to_uid(str_names[i])
	_timer_stop_start("ResourceUID.path_to_uid() (exists)")
	for i: int in range(1000): ResourceUID.path_to_uid(existing_uid)
	_timer_stop_start("ResourceUID.text_to_id(ResourceUID.path_to_uid()) (exists)")
	for i: int in range(1000): ResourceUID.text_to_id(ResourceUID.path_to_uid(existing_uid))
	_timer_stop_start("ResourceUID.get_id_path(ResourceUID.text_to_id(existing_uid) (exists)")
	for i: int in range(1000): ResourceUID.get_id_path(ResourceUID.text_to_id(existing_uid))
	_timer_stop_start(".begins_with(uid://) (false)")
	for i: int in range(1000): str_names[i].begins_with("uid://")
	_timer_stop_start(".begins_with(uid://) (true)")
	for i: int in range(1000): str_uids[i].begins_with("uid://")
	_timer_stop_start("_has_path() (not uid)")
	for i: int in range(1000): _has_path(str_names[i], str_names, str_names)
	_timer_stop_start("_has_path() (bad uid)")
	for i: int in range(1000): _has_path(str_uids[i], str_names, str_names)
	_timer_stop_start("_has_path() (existing_uid)")
	for i: int in range(1000): _has_path(existing_uid, str_names, str_names)

	_timer_stop()



# TODO MORE TESTING
func _has_path(path: String, list: PackedStringArray, str_names_pretend_cache: PackedStringArray) -> bool:
	if path.begins_with("uid://"):
		return list.has(path)
	else:
		return str_names_pretend_cache.has(path)
