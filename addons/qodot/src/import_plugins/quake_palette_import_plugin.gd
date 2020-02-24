class_name QuakePaletteImportPlugin
extends EditorImportPlugin
tool

# Quake .map import plugin

func get_importer_name() -> String:
	return 'qodot.palette'

func get_visible_name() -> String:
	return 'Quake Palette'

func get_resource_type() -> String:
	return 'Resource'

func get_recognized_extensions() -> Array:
	return ['lmp']

func get_save_extension() -> String:
	return 'tres'

func get_import_options(preset) -> Array:
	return []

func get_preset_count() -> int:
	return 0

func import(source_file, save_path, options, r_platform_variants, r_gen_files) -> int:
	var save_path_str : String = '%s.%s' % [save_path, get_save_extension()]

	var file := File.new()
	var err : int = file.open(source_file, File.READ)

	if err != OK:
		print(['Error opening .lmp file: ', err])
		return err

	var colors := PoolColorArray()

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
