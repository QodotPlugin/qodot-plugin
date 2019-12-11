class_name QodotBuildPipeline

static func get_build_steps() -> Array:
	return []

static func initialize_context(map_file: String, base_texture_path: String, material_extension: String, texture_extension: String, texture_wads: Array, default_material: Material) -> Dictionary:
	print("Parsing map file...")
	var map_parse_profiler = QodotProfiler.new()
	var map_reader = QuakeMapReader.new()
	var parsed_map = map_reader.parse_map(map_file)
	var map_parse_duration = map_parse_profiler.finish()
	print("Done in " + String(map_parse_duration * 0.001) +  " seconds.\n")

	var entity_properties_array = parsed_map[0]
	var brush_data_dict = parsed_map[1]

	var worldspawn_properties = entity_properties_array[0]
	var entity_count = entity_properties_array.size()

	print("Entity Count: " + String(entity_count))

	var brush_count = 0
	for entity_idx in brush_data_dict:
		brush_count += brush_data_dict[entity_idx].size()

	print("Brush Count: " + String(brush_count) + "\n")

	print("Worldspawn Properties:")
	print(worldspawn_properties)

	print("\nLoading textures...")
	var texture_load_profiler = QodotProfiler.new()
	var texture_list = map_reader.get_texture_list(brush_data_dict)
	var texture_loader = QodotTextureLoader.new()
	var material_dict = texture_loader.load_texture_materials(
		texture_list,
		base_texture_path,
		material_extension,
		texture_extension,
		texture_wads,
		default_material
	)
	var texture_load_duration = texture_load_profiler.finish()
	print("Done in " + String(texture_load_duration * 0.001) + " seconds.\n")

	print("Map textures:")
	print(texture_list)

	return {
		"entity_properties_array": entity_properties_array,
		"brush_data_dict": brush_data_dict,
		"material_dict": material_dict
	}
