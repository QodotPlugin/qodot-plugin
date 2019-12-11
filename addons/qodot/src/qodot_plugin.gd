class_name QodotPlugin
extends EditorPlugin
tool

# Qodot editor plugin

var map_import_plugin = null
var palette_import_plugin = null
var wad_import_plugin = null

func _enter_tree():
	map_import_plugin = QuakeMapImportPlugin.new()
	palette_import_plugin = QuakePaletteImportPlugin.new()
	wad_import_plugin = QuakeWadImportPlugin.new()

	add_import_plugin(map_import_plugin)
	add_import_plugin(palette_import_plugin)
	add_import_plugin(wad_import_plugin)

func _exit_tree():
	remove_import_plugin(map_import_plugin)
	remove_import_plugin(palette_import_plugin)
	remove_import_plugin(wad_import_plugin)

	map_import_plugin = null
	palette_import_plugin = null
	wad_import_plugin = null
