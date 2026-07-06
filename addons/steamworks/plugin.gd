@tool
extends EditorPlugin
## Wrapper for GodotSteam plugin, to handle initialization, common vars, and enabling / disabling steam

func _enable_plugin() -> void:
	#assert(_does_steam_exist(), "Steam is a dependency youknow!!!")			# TODO make it OK without Steam singleton
	add_autoload_singleton("Steamworks", "res://addons/steamworks/steamworks.gd")
	_ensure_good_settings()


func _disable_plugin() -> void:
	remove_autoload_singleton("Steamworks")


func _enter_tree() -> void:
	_ensure_good_settings()


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	pass


func _ensure_good_settings() -> void:
	if _does_steam_exist() and not _are_settings_valid():
		push_warning("Steamworks: project settings are not valid! Will correct them for you...")
		ProjectSettings.set_setting("steam/initialization/initialize_on_startup", false)
		ProjectSettings.set_setting("steam/initialization/embed_callbacks", false)


func _does_steam_exist() -> bool:
	return (Engine.has_singleton(&"Steam")
	and ProjectSettings.has_setting("steam/initialization/initialize_on_startup")
	and ProjectSettings.has_setting("steam/initialization/embed_callbacks")
	and ProjectSettings.has_setting("steam/initialization/app_id")
	)


func _are_settings_valid() -> bool:
	return (ProjectSettings.get_setting("steam/initialization/embed_callbacks", true) == false
	and ProjectSettings.get_setting("steam/initialization/initialize_on_startup", true) == false)
