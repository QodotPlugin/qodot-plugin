class_name QodotBuildParseMap
extends QodotBuildStep

func get_name() -> String:
	return "parse_map"

func get_type() -> int:
	return self.Type.SINGLE

func get_build_params() -> Array:
	return [
		'map_file'
	]

func _run(context) -> Dictionary:
	var map_file = context['map_file']

	print("Parsing map file...")
	var map_parse_profiler = QodotProfiler.new()
	var map_reader = QuakeMapReader.new()
	var parsed_map = map_reader.parse_map(map_file)
	var map_parse_duration = map_parse_profiler.finish()
	print("Done in " + String(map_parse_duration * 0.001) +  " seconds.\n")

	var entity_properties_array = parsed_map[0]
	var brush_data_dict = parsed_map[1]

	return {
		'entity_properties_array': entity_properties_array,
		'brush_data_dict': brush_data_dict
	}
