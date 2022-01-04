@tool
class_name QuakePaletteImportPlugin
extends EditorImportPlugin

# Quake super.map import plugin

func _get_importer_name() -> String:
	return 'qodot.palette'

func _get_visible_name() -> String:
	return 'Quake Palette'

func _get_resource_type() -> String:
	return 'Resource'

func _get_recognized_extensions() -> Array:
	return ['lmp']

func _get_save_extension() -> String:
	return 'tres'

func _get_import_options(path, preset):
	return []

func _get_preset_count() -> int:
	return 0
	
func _get_import_order():
	return 0

func _import(source_file, save_path, options, r_platform_variants, r_gen_files) -> int:
	var save_path_str : String = '%s.%s' % [save_path, _get_save_extension()]

	var file := File.new()
	var err : int = file.open(source_file, File.READ)

	if err != OK:
		print(['Error opening super.lmp file: ', err])
		return err

	var colors := PackedColorArray()

	while true:
		var red : int = file.get_8()
		var green : int = file.get_8()
		var blue : int = file.get_8()
		var color := Color(red / 255.0, green / 255.0, blue / 255.0)

		colors.append(color)

		if file.eof_reached():
			break

		if colors.size() == 256:
			break

	var palette_resource := QuakePaletteFile.new(colors)

	return ResourceSaver.save(save_path_str, palette_resource)
