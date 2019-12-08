class_name QuakeMapImportPlugin
extends EditorImportPlugin
tool

# Quake .map import plugin

func get_importer_name():
	return 'qodot.map'

func get_visible_name():
	return 'Quake Map'

func get_resource_type():
	return 'Resource'

func get_recognized_extensions():
	return ['map']

func get_save_extension():
	return 'tres'

func get_import_options(preset):
	return []

func get_preset_count():
	return 0

func import(source_file, save_path, options, r_platform_variants, r_gen_files):
	var save_path_str = '%s.%s' % [save_path, get_save_extension()]

	var map_resource = null

	var existing_resource := load(save_path_str) as QuakeMapFile
	if(existing_resource != null):
		map_resource = existing_resource
		map_resource.revision += 1
	else:
		map_resource = QuakeMapFile.new()

	return ResourceSaver.save(save_path_str, map_resource)
