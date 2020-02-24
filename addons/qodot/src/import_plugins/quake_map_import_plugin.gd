class_name QuakeMapImportPlugin
extends EditorImportPlugin
tool

# Quake .map import plugin

func get_importer_name() -> String:
	return 'qodot.map'

func get_visible_name() -> String:
	return 'Quake Map'

func get_resource_type() -> String:
	return 'Resource'

func get_recognized_extensions() -> Array:
	return ['map']

func get_save_extension() -> String:
	return 'tres'

func get_import_options(preset) -> Array:
	return []

func get_preset_count() -> int:
	return 0

func import(source_file, save_path, options, r_platform_variants, r_gen_files) -> int:
	var save_path_str = '%s.%s' % [save_path, get_save_extension()]

	var map_resource : QuakeMapFile = null

	var existing_resource := load(save_path_str) as QuakeMapFile
	if(existing_resource != null):
		map_resource = existing_resource
		map_resource.revision += 1
	else:
		map_resource = QuakeMapFile.new()

	return ResourceSaver.save(save_path_str, map_resource)
