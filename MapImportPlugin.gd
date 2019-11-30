tool
class_name MapImportPlugin
extends EditorImportPlugin

enum Presets { PRESET_DEFAULT }

func get_importer_name():
	return "qodot.map"

func get_visible_name():
	return "Quake Map"

func get_recognized_extensions():
	return ["map"]

func get_save_extension():
	return "tres"

func get_resource_type():
	return "QuakeMap"

func get_preset_count():
	return Presets.size()

func get_preset_name(preset):
	match preset:
		Presets.PRESET_DEFAULT:
			return "Default"
		_:
			return "Unknown"

func get_import_options(preset):
	return []

func get_option_visibility(option, options):
	return true

func import(source_file, save_path, options, r_platform_variants, r_gen_files):
	
	print("Importing ", source_file, " to be saved in ", save_path, " with options ", options)
	var file = File.new()
	QodotUtil.debug_print("Opening file")
	var err = file.open(source_file, File.READ)
	if err != OK:
		QodotUtil.debug_print(["Error opening file: ", err])
		return err
	
	var quake_map_reader = QuakeMapReader.new()
	var quake_map: QuakeMap = quake_map_reader.read_map_file(file, options)
	
	for entity in quake_map.entities:
		QodotUtil.debug_print(entity)
		for brush in entity.brushes:
			QodotUtil.debug_print(["\t", brush])
			for plane in brush.planes:
				QodotUtil.debug_print(["\t\t", plane])
	
	file.close()
	
	var save_path_str = "%s.%s" % [save_path, get_save_extension()]
	
	QodotUtil.debug_print(["Saving ", quake_map, " to ", save_path_str])
	var result = ResourceSaver.save(save_path_str, quake_map)
	QodotUtil.debug_print(["ResourceSaver result: ", result])
	
	# Attempt to forcefully reload the asset
	quake_map = null
	quake_map = load(save_path_str)
	
	return result
