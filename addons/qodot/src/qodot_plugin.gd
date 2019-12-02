class_name QodotPlugin
extends EditorPlugin
tool

# Qodot editor plugin

var map_import_plugin

func _enter_tree():
	map_import_plugin = preload('quake_map_import_plugin.gd').new()
	add_import_plugin(map_import_plugin)

func _exit_tree():
	remove_import_plugin(map_import_plugin)
	map_import_plugin = null
