class_name QuakePaletteImportPlugin
extends EditorImportPlugin
tool

# Quake .map import plugin

func get_importer_name():
	return 'qodot.palette'

func get_visible_name():
	return 'Quake Palette'

func get_resource_type():
	return 'Resource'

func get_recognized_extensions():
	return ['lmp']

func get_save_extension():
	return 'tres'

func get_import_options(preset):
	return []

func get_preset_count():
	return 0

func import(source_file, save_path, options, r_platform_variants, r_gen_files):
	var save_path_str = '%s.%s' % [save_path, get_save_extension()]

	var file = File.new()
	var err = file.open(source_file, File.READ)

	if err != OK:
		print(['Error opening .lmp file: ', err])
		return false

	var colors = PoolColorArray()

	while true:
		var red = file.get_8()
		var green = file.get_8()
		var blue = file.get_8()
		var color = Color(red / 255.0, green / 255.0, blue / 255.0)

		colors.append(color)

		if file.eof_reached():
			break

		if colors.size() == 256:
			break

	var palette_resource = QuakePaletteFile.new(colors)

	return ResourceSaver.save(save_path_str, palette_resource)
