class_name QuakeMapReader

# Utility class for parsing a quake .map file into a QuakeMap instance
# Separate from the import code to allow for runtime usage

const OPEN_BRACKET = '('
const CLOSE_BRACKET = ')'

var inverse_scale_factor = 1.0

func _init(inverse_scale_factor):
	self.inverse_scale_factor = inverse_scale_factor

func parse_map(map_path: String) -> Dictionary:
	var file = File.new()
	var err = file.open(map_path, File.READ)

	if err != OK:
		print(['Error opening .map file: ', err])
		return {}

	var map_lines = []
	while not file.eof_reached():
		var line = file.get_line()
		if not line.begins_with('//'):
			map_lines.append(line)

	var line_numbers = find_line_numbers(map_lines)

	var parsed_entities = []
	var parsed_brushes = {}

	for entity_idx in range(0, line_numbers.size()):
		var current_entity = line_numbers[entity_idx]
		var next_entity = line_numbers[entity_idx + 1] if entity_idx < line_numbers.size() - 1 else null

		var entity_start = current_entity[0]
		var entity_end = map_lines.size()

		if next_entity:
			entity_end = next_entity[0]

		var entity_lines = []
		for line_idx in range(entity_start - 1, entity_end - 1):
			entity_lines.append(map_lines[line_idx])

		parsed_entities.append(entity_lines)
		parsed_brushes[entity_idx] = {}

		var brush_line_numbers = line_numbers[entity_idx][1]

		for brush_idx in range(0, brush_line_numbers.size()):
			var current_brush = brush_line_numbers[brush_idx]
			var next_brush = brush_line_numbers[brush_idx + 1] if brush_idx < brush_line_numbers.size() - 1 else null

			var brush_start = current_brush
			var brush_end = brush_line_numbers.size()

			if next_brush:
				brush_end = next_brush
			else:
				brush_end = entity_end - 1

			var brush_lines = []
			for line_idx in range(brush_start, brush_end - 2):
				brush_lines.append(map_lines[line_idx])

			parsed_brushes[entity_idx][brush_idx] = brush_lines

	var entity_properties = []
	for parsed_entity in parsed_entities:
		entity_properties.append(read_entity_properties(parsed_entity))

	for entity_idx in parsed_brushes:
		var entity_brushes = parsed_brushes[entity_idx]
		for brush_idx in entity_brushes:
			var parsed_brush = entity_brushes[brush_idx]
			for face_idx in range(0, parsed_brush.size()):
				var face_line = parsed_brush[face_idx]
				parsed_brushes[entity_idx][brush_idx][face_idx] = parse_face(face_line)

	return {
		'entity_properties': entity_properties,
		'brush_data': parsed_brushes
	}

func find_line_numbers(map_string: Array):
	var line_numbers = []

	var is_inside_entity = false
	var is_inside_brush = false

	var line_number = 1
	for line in map_string:
		var first_char = line.substr(0, 1)

		if not is_inside_entity and not is_inside_brush:
			if first_char == "{":
				is_inside_entity = true
				line_numbers.append([line_number, []])
			elif first_char == "}":
				print("Error: Closing brace encountered outside entity")
				return null
		elif is_inside_brush:
			if first_char == "{":
				print("Error: Opening brance encountered inside brush")
				return null
			elif first_char == "}":
				is_inside_brush = false
		elif is_inside_entity:
			if first_char == "{":
				is_inside_brush = true
				line_numbers[-1][1].append(line_number)
			elif first_char == "}":
				is_inside_entity = false

		line_number += 1

	return line_numbers

func read_entity_properties(entity_lines: Array) -> Dictionary:
	var properties = {}

	var line_number = 0

	while true:
		if(line_number >= entity_lines.size()):
			break

		var line = entity_lines[line_number]

		if line.substr(0, 1) == "}":
			break

		if line_is_property(line):
			var key = line_property_key(line)
			var value = line_property_value(line)
			match key:
				'origin':
					properties[key] = parse_vertex(value)
				'angle':
					properties[key] = float(value)
				_:
					properties[key] = value

		line_number += 1

	return properties

func parse_face(line: String) -> Array:
	QodotUtil.debug_print(['Face: ', line])

	# Parse vertices
	var first_open_bracket = line.find(OPEN_BRACKET, 0)
	var second_open_bracket = line.find(OPEN_BRACKET, first_open_bracket + 1)
	var third_open_bracket = line.find(OPEN_BRACKET, second_open_bracket + 1)

	var first_close_bracket = line.find(CLOSE_BRACKET, 0)
	var second_close_bracket = line.find(CLOSE_BRACKET, first_close_bracket + 1)
	var third_close_bracket = line.find(CLOSE_BRACKET, second_close_bracket + 1)

	var first_vertex = parse_vertex(line.substr(first_open_bracket + 2, first_close_bracket - first_open_bracket - 2))
	var second_vertex = parse_vertex(line.substr(second_open_bracket + 2, second_close_bracket - second_open_bracket - 2))
	var third_vertex = parse_vertex(line.substr(third_open_bracket + 2, third_close_bracket - third_open_bracket - 2))

	var vertices = [first_vertex, second_vertex, third_vertex]
	QodotUtil.debug_print(['Vertices: ', vertices])

	# Parse texture parameters
	var loose_params = Array(line.substr(third_close_bracket + 2, line.length()).split(' '))
	QodotUtil.debug_print(['Loose params: ', loose_params])

	var texture = String(loose_params.pop_front())
	QodotUtil.debug_print(['Texture: ', texture])

	var uv = null
	var first_uv_param = loose_params.pop_front()
	if(first_uv_param == '['):
		var u = [
			loose_params.pop_front(),
			loose_params.pop_front(),
			loose_params.pop_front(),
			loose_params.pop_front()
		]
		loose_params.pop_front()
		loose_params.pop_front()
		var v = [
			loose_params.pop_front(),
			loose_params.pop_front(),
			loose_params.pop_front(),
			loose_params.pop_front()
		]
		loose_params.pop_front()

		uv = [
			u[0], u[1], u[2], float(u[3]) / inverse_scale_factor,
			v[0], v[1], v[2], float(v[3]) / inverse_scale_factor
		]
	else:
		uv = [float(first_uv_param) / inverse_scale_factor, float(loose_params.pop_front()) / inverse_scale_factor]

	QodotUtil.debug_print(['UV: ', uv])

	var rotation = float(loose_params.pop_front())
	QodotUtil.debug_print(['Rotation: ', rotation])

	var scale = Vector2(loose_params.pop_front(), loose_params.pop_front())
	QodotUtil.debug_print(['Scale: ', scale])

	var bitmask_params = []
	while loose_params.size() > 0:
		bitmask_params.append(int(loose_params.pop_front()))

	return [vertices, texture, uv, rotation, scale, bitmask_params]

func parse_vertex(vertex_substr: String) -> Vector3:
	var comps = vertex_substr.split(' ')
	return Vector3(comps[1], comps[2], comps[0]) / inverse_scale_factor

func line_starts_with(line: String, prefix: String):
	return line.substr(0, prefix.length()) == prefix

func line_is_property(line):
	return line_starts_with(line, '"')

func line_property_key(line):
	return line.substr(1, line.find('"', 1) - 1)

func line_property_value(line):
	var escaped_quote = '"'
	var first_quote = line.find(escaped_quote)
	var second_quote = line.find(escaped_quote, first_quote + 1)
	var third_quote = line.find(escaped_quote, second_quote + 1)
	var fourth_quote = line.find(escaped_quote, third_quote + 1)
	return line.substr(third_quote + 1, line.length() - (third_quote + 2))
