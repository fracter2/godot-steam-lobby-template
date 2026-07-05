@tool
class_name LobbyConnecter
extends Node
## When entering tree, sets the [member multiplayer.multiplayer_peer] for the current scene in the tree.
## If the lobby disconnects, and [member quit_on_lobby_missing] is [code]true[/code], the lobby quits to main menu.[br]
## This class is meant to represent the entire scene's dependancy on the Lobby multiplayer connection.


@export var quit_on_lobby_missing: bool = true									# TODO consider having it instead PAUSE the world + ui prompt


#
# ---- PROCEDURE ----
#

func _enter_tree() -> void:
	# We are nice, we don't edit in editor without explaining and asking for permission.
	# To show how it's intended behaviour, and enforce it.
	if Engine.is_editor_hint():
		if not owner.editor_state_changed.is_connected(update_configuration_warnings):
			owner.editor_state_changed.connect(update_configuration_warnings)
		update_configuration_warnings()
	# ... in case of ignorance
	elif not _is_connected_propperly():
		_connect_to_owner()


#
# ---- Editor Functionality ----
#

func _get_configuration_warnings() -> PackedStringArray:
	if not _is_connected_propperly():
		notify_property_list_changed()
		return [
			"This needs to be connected to the owner (scene root) enter_tree signal! To set multiplayer peer asap. \n
			Either press the button in the inspector, or connect '_try_set_multiplayer' func to owner 'tree_entered()' signal."
			]
	else:
		return []


func _get_property_list() -> Array[Dictionary]:
	var properties: Array[Dictionary] = []
	if not _is_connected_propperly():
		properties.append({
			"name" : "connect_to_owner_tool",
			"type" : TYPE_CALLABLE,
			"hint" : PROPERTY_HINT_TOOL_BUTTON,
			"hint_string" : "connect_to_owner"
			})
	return properties


func _get(property: StringName) -> Variant:
	if property == &"connect_to_owner_tool":
		return _connect_tool
	return null


func _connect_tool() -> void:
	if Engine.is_editor_hint():
		var undo_redo: EditorUndoRedoManager =EditorInterface.get_editor_undo_redo()
		undo_redo.create_action("Connecting LobbyConnector to owner")
		undo_redo.add_do_method(self, &"_connect_to_owner")
		undo_redo.add_undo_method(self, &"_disconnect_from_owner")
		undo_redo.commit_action()
		update_configuration_warnings()


#
# ---- INTERNAL ----
#

func _is_connected_propperly() -> bool:
	return owner.tree_entered.is_connected(_try_set_multiplayer)


func _connect_to_owner() -> void:
	if not _is_connected_propperly():
		owner.tree_entered.connect(_try_set_multiplayer, ConnectFlags.CONNECT_PERSIST)


func _disconnect_from_owner() -> void:
	if _is_connected_propperly():
		owner.tree_entered.disconnect(_try_set_multiplayer)


#
# ---- SIGNALS ----
#

func _try_set_multiplayer() -> void:
	if Engine.is_editor_hint():
		return

	assert((not is_inside_tree() and owner.is_inside_tree()), "This is supposed to be called when owner enters tree, which means this node has yet to enter itself. Called at wrong time")
	# NOTE this is why "owner.multiplayer"  or "owner.get_tree()" is used instead of just "multiplayer" or "get_tree()"

	if Lobby.is_in_lobby():
		_on_lobby_entered()
	else:
		if quit_on_lobby_missing:
			_quit_to_menu()
		else:
			push_warning("Started game without being in a lobby! Is this ok?")
			Lobby.lobby_entered.connect(_on_lobby_entered, ConnectFlags.CONNECT_ONE_SHOT)			# Oneshot to clarify use-case

	Lobby.lobby_exiting.connect(_on_lobby_exiting)													# NOTE Consider deffered, to avouid quitting in the middle of processing... maybe helpfull?
	owner.multiplayer.server_disconnected.connect(_on_lobby_exiting.bind("Server disconnected"))


func _on_lobby_entered() -> void:
	owner.multiplayer.multiplayer_peer = Lobby.multiplayer.multiplayer_peer
	Log.pprint("GAME: JUST JOINED AS PEER %d" % [owner.multiplayer.get_unique_id()])


func _on_lobby_exiting(message: String) -> void:
	Log.pprint("Quit level, message: %s" % message)
	if quit_on_lobby_missing:
		_quit_to_menu()


func _quit_to_menu() -> void:
	if owner.is_inside_tree():	# In case this gets called when it's already being unloaded / elsewhere
		owner.get_tree().change_scene_to_file(PATHS.MAIN_MENU)
