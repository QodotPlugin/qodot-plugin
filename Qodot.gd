tool
extends EditorPlugin

var map_import_plugin

func _enter_tree():
    map_import_plugin = preload("MapImportPlugin.gd").new()
    add_import_plugin(map_import_plugin)

func _exit_tree():
    remove_import_plugin(map_import_plugin)
    map_import_plugin = null
