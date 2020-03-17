class_name QodotUtil

# General-purpose utility functions namespaced to Qodot for compatibility

const DEBUG := false

const CATEGORY_STRING := '----------------------------------------------------------------'

# Const-predicated print function to avoid excess log spam
static func debug_print(msg) -> void:
	if(DEBUG):
		print(msg)

static func newline() -> String:
	if OS.get_name() == "Windows":
		return "\r\n"
	else:
		return "\n"

static func category_dict(name: String) -> Dictionary:
	return property_dict(name, TYPE_STRING, -1, "", PROPERTY_USAGE_CATEGORY)

static func property_dict(name: String, type: int, hint: int = -1, hint_string: String = "", usage: int = -1) -> Dictionary:
	var dict := {
		'name': name,
		'type': type
	}

	if hint != -1:
		dict['hint'] = hint

	if hint_string != "":
		dict['hint_string'] = hint_string

	if usage != -1:
		dict['usage'] = usage

	return dict
