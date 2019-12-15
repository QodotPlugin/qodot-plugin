class_name QodotBuildParseMap
extends QodotBuildStep

func get_name() -> String:
	return "parse_map"

func get_type() -> int:
	return self.Type.SINGLE

func get_build_params() -> Array:
	return [
		'map_file',
		'inverse_scale_factor'
	]

func _run(context) -> Dictionary:
	var map_file = context['map_file']
	var inverse_scale_factor = context['inverse_scale_factor']

	print("Parsing map file...")
	var map_parse_profiler = QodotProfiler.new()
	var map_reader = QuakeMapReader.new(inverse_scale_factor)
	var parsed_map = map_reader.parse_map(map_file)
	var map_parse_duration = map_parse_profiler.finish()
	print("Done in " + String(map_parse_duration * 0.001) +  " seconds.\n")

	return {
		'entity_properties_array': parsed_map['entity_properties'],
		'brush_data_dict': parsed_map['brush_data']
	}
