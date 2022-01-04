@tool
class_name QuakeMapImportPlugin
extends EditorImportPlugin

# Quake super.map import plugin

func _get_importer_name() -> String:
	return 'qodot.map'

func _get_visible_name() -> String:
	return 'Quake Map'

func _get_resource_type() -> String:
	return 'Resource'

func _get_recognized_extensions() -> Array:
	return ['map']
	
func _get_priority():
	return 1.0

func _get_save_extension() -> String:
	return 'tres'

func _get_import_options(path, preset):
	return []

func _get_preset_count() -> int:
	return 0
	
func _get_import_order():
	return 0

func _import(source_file, save_path, options, r_platform_variants, r_gen_files) -> int:
	var save_path_str = '%s.%s' % [save_path, _get_save_extension()]

	var map_resource : QuakeMapFile = null

	var existing_resource := load(save_path_str) as QuakeMapFile
	if(existing_resource != null):
		map_resource = existing_resource
		map_resource.revision += 1
	else:
		map_resource = QuakeMapFile.new()

	return ResourceSaver.save(save_path_str, map_resource)
