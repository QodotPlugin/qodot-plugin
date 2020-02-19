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
