extends Node

# This is a standalone utility script (meant as an autoload) to make it easier to
# parse commandline args. "has_command()" and "get_values()" are the primary intended uses.
#
# This script removes prefixes (usually -- but can also be any combination of - or +) and
# parses values with what i call "space" style values and '=' style values.

var main_commands: Dictionary[String, PackedStringArray] = {}
var user_commands: Dictionary[String, PackedStringArray] = {}

#
# ---- API ----
#

## Returns if euther main or user commands contain this (only one may have it).[br]
## Any word begining with [code]-[/code] or [code]+[/code] are considered keys.[br]
## Ex: [codeblock lang=text]-key1 --key2 +key3 ++key4 --+-key5 [/codeblock][br]
## NOTE Sanitizes the input key with sanitize_key().
func has_command(key: String) -> bool:
	var sanitized_key: String = sanitize_key(key)
	return main_commands.has(sanitized_key) or user_commands.has(sanitized_key)

## Returns the [PackedStringArray] values of the corresponding [param key].[br]
## [br]
## When first parsed, the launch args are first separated into words with spaces. Any command-valid word is a key. [br]
## Any following words (that are not other keys) are that key's values. This is space-style values.[br]
## Ex: [codeblock lang=text] --space_style_key value1 value2... [/codeblock]
## [br]
## [b]NOTE[/b] Values can also be appended in the same word as the key using [code]=[/code]. This is '=' style values.[br]
## Ex: [codeblock lang=text] --equal_style_key=value1=value2...[/codeblock]
## Ex: [codeblock lang=text] --also_valid_key=value1 value2 value3=still=value3 [/codeblock]
## [br]
## NOTE Both empty values and bad keys return an empty array.[br]
## NOTE Sanitizes [param key] with [method sanitize_key] just like all keys. [br]
func get_values(key: String) -> PackedStringArray:
	var sanitized_key: String = sanitize_key(key)
	if main_commands.has(sanitized_key):
		return main_commands[sanitized_key]
	elif user_commands.has(sanitized_key):
		return user_commands[sanitized_key]
	else:
		return []

## Conforms the input string to a valid key.[br]
## NOTE result is the same as: [codeblock lang=gdscript] key.to_lower().remove_chars(":/?*\"|\\%<>").strip_escapes().lstrip("-+"). [/codeblock]
func sanitize_key(key: String) -> String:
	return (key
		.to_lower()						# To avoid capitalization inconsistensies
		.remove_chars(":/?*\"|\\%<>")	# To prevent unintended string logic
		.strip_escapes()				# To prevent unintended string logic
		.lstrip("-+")					# To remove key-signifier
		)


#
# ---- Procedure ----
#

func _init() -> void:
	main_commands = _parse_commands(OS.get_cmdline_args())
	user_commands = _parse_commands(OS.get_cmdline_user_args())

	# Remove overlapping keys to enforce main_commands > user_commands
	for key: String in main_commands.keys():
		if user_commands.has(key):
			user_commands.erase(key)

	print("---- parsed cmd args ----")
	for key: String in main_commands.keys():
		print("\t%s: %s" % [key, main_commands[key]])
	print("----")
	print("---- parsed user cmd args ----")
	for key: String in user_commands.keys():
		print("\t%s: %s" % [key, user_commands[key]])
	print("----")

#
# ---- Internal logic ----
#

## Parses a PackedStringArray to allow both "=" style args (key=value1=value2...) and spaced args (--key value1 value2...). [br]
## Though "=" inside a spaced-style arg are kept.
func _parse_commands(source: PackedStringArray) -> Dictionary[String, PackedStringArray]:
	var out_dict: Dictionary[String, PackedStringArray] = {}
	var new_command_key: String = ""
	var new_command_value: PackedStringArray = []
	for arg: String in source:
		if _is_command(arg):
			# Push previous key before starting new
			if !new_command_key.is_empty():
				out_dict.set(new_command_key, new_command_value.duplicate())
			new_command_value = arg.split("=")
			new_command_key = sanitize_key(new_command_value[0])					# First slice is always the key (even if = is not used)
			new_command_value.remove_at(0)

		else:
			new_command_value.append(arg)

	# Remember to push the last command
	if not new_command_key.is_empty():
		out_dict.set(new_command_key, new_command_value.duplicate())

	return out_dict

# Returns if this is read as a key (command) rather than a space style arg (--key value1 value2...)
func _is_command(txt: String) -> bool:
	return txt.begins_with("-") or txt.begins_with("+")
