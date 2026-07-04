extends Node


var loading_scenes: Array[LoadingProgress] = []

signal done_loading(file_path: String, resource: Resource)
signal loading_progressed(file_path: String, progress_ratio: float)


#
# ---- API ----
#

## Gets the cached resource if available. else, sets the path to load using [method prepare].
func get_cached_or_prepare(file_path: String, keep_when_done: bool = false, keep_on_change_scene: bool = false) -> Resource:
	print_verbose("BackgroundLoader: get_cached_or_prepare() for path: %s" % file_path)
	if ResourceLoader.has_cached(file_path):
		if is_file_in_progress_or_kept(file_path):
			_get_file_in_progress(file_path).has_changed_scene = false
		return ResourceLoader.get_cached_ref(file_path)
	else:
		prepare(file_path, keep_when_done, keep_on_change_scene)
		return null


## Sets the scene at [param file_path] to start loading in the background. [param keep_when_done] dictates if a reference should be kept here, until [method reset] or [method undo_prepare] are called, or tree changes scene. It's kept for one scene change, or more if [param keep_on_change_scene] is true.
func prepare(file_path: String, keep_when_done: bool = false, keep_on_change_scene: bool = false) -> void:
	if not ResourceLoader.exists(file_path):
		push_error("BackgroundLoader Tried to load non-existent scene: %s, from %s" % [file_path, get_stack()])
		return

	if ResourceLoader.has_cached(file_path) or is_file_in_progress_or_kept(file_path):
		if is_file_in_progress_or_kept(file_path):
			_get_file_in_progress(file_path).has_changed_scene = false			# Set it so it doesn't get removed after changed scene signal
		return

	var err: Error = ResourceLoader.load_threaded_request(file_path)
	if err:
		push_error("Error in background_loader.prepare() with path %s. Error: %s" % [file_path, str(err)])
		breakpoint
		return

	var new_prog: LoadingProgress = LoadingProgress.new(file_path, keep_when_done, keep_on_change_scene)
	new_prog.progress.connect(_on_progress_updated.bind(new_prog.file_path))
	new_prog.ready.connect(_on_done_loading.bind(new_prog.file_path))
	loading_scenes.append(new_prog)


## Removes a kept file path, allowing it to possibly be unreferenced from the [ResourceLoader] cache.
func undo_prepare(file_path: String) -> void:
	var target: LoadingProgress = _get_file_in_progress(file_path)
	if target != null:
		loading_scenes.erase(target)


## Removes all kept file paths, possibly allowing them to be removed from the [ResourceLoader] cache.
func reset() -> void:
	loading_scenes.clear()


func is_file_in_progress(file_path: String) -> bool:
	for p: LoadingProgress in loading_scenes:
		if p.file_path == file_path and not p.done:
			return true

	return false


func is_file_in_progress_or_kept(file_path: String) -> bool:
	for p: LoadingProgress in loading_scenes:
		if p.file_path == file_path:
			return true

	return false

#
# ---- PROCEDURE ----
#

func _enter_tree() -> void:
	get_tree().scene_changed.connect(_on_scene_changed)
	#get_tree().process_frame.connect()

	await get_tree().current_scene.ready

	_on_scene_changed()


func _process(_delta: float) -> void:
	var objects_to_unref: Array[LoadingProgress] = []

	for load_prog: LoadingProgress in loading_scenes:
		if load_prog.done: continue

		var progress: Array
		var status : int = ResourceLoader.load_threaded_get_status(load_prog.file_path, progress)
		var progress_ratio: float = 0
		if progress != null and (not progress.is_empty()) and progress[0] is float:
			progress_ratio = (progress[0] as float)

		load_prog.update(progress_ratio)

		if status == ResourceLoader.THREAD_LOAD_LOADED:
			load_prog.done = true
			load_prog.finish(ResourceLoader.load_threaded_get(load_prog.file_path))
			if not load_prog.keep_when_done:
				objects_to_unref.append(load_prog)

		elif not ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			push_error("Backgroundloader failed to load resource %s! error code (prob just fail code): %d" % [load_prog.file_path, status])
			load_prog.failed.emit()
			objects_to_unref.append(load_prog)

	for p: LoadingProgress in objects_to_unref:
		loading_scenes.erase(p)


#
# ---- SIGNAL CALLBACKS ----
#

func _on_scene_changed() -> void:
	var objects_to_unref: Array[LoadingProgress] = []

	for p: LoadingProgress in loading_scenes:
		if p.has_changed_scene and not p.keep_when_change_scene:
			objects_to_unref.push_back(p)
		p.has_changed_scene = true												# Since this signal calls AFTER entering a tree, this is set AFTER

	for p: LoadingProgress in objects_to_unref:
		loading_scenes.erase(p)


func _on_progress_updated(progress_ratio: float, file_path: String) -> void:
	loading_progressed.emit(file_path, progress_ratio)


func _on_done_loading(resource: Resource, file_path: String) -> void:
	done_loading.emit(file_path, resource)

#
# ---- INTERNAL ....
#

func _get_file_in_progress(file_path: String) -> LoadingProgress:
	for p: LoadingProgress in loading_scenes:
		if p.file_path == file_path:
			return p

	return null


class LoadingProgress extends RefCounted:
	var file_path: String = ""
	var progress_ratio: float = 0
	var keep_when_change_scene: bool = false
	var has_changed_scene: bool = false
	var keep_when_done: bool = false
	var done: bool = false
	var resource: Resource = null
	signal progress(new_ratio: float)
	signal ready(resource: Resource)
	signal failed()


	func _init(path: String, keep_on_done: bool, keep_on_change_scene: bool) -> void:
		file_path = path
		keep_when_done = keep_on_done
		keep_when_change_scene = keep_on_change_scene


	func update(new_ratio: float) -> void:
		if progress_ratio != new_ratio and not done:
			progress_ratio = new_ratio
			progress.emit(new_ratio)


	func finish(res: Resource) -> void:
		done = true
		resource = res
		progress.emit(1)
		ready.emit(resource)
