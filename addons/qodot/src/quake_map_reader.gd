class_name QuakeMapReader

# Utility class for parsing a quake .map file into a QuakeMap instance
# Separate from the import code to allow for runtime usage

const OPEN_BRACKET = '('
const CLOSE_BRACKET = ')'

var map_string: PoolStringArray
var line_numbers: Array

func open_map(map_path: String):
	var file = File.new()
	var err = file.open(map_path, File.READ)

	if err != OK:
		print(['Error opening .map file: ', err])
		return false

	while not file.eof_reached():
		map_string.append(file.get_line())

	line_numbers = read_indices()

	return true

func close_map():
	map_string.resize(0)
	line_numbers.resize(0)

func get_entity_count() -> int:
	return line_numbers.size()

func get_brush_count() -> int:
	var total = 0
	for entity_idx in line_numbers:
		total += get_entity_brush_count(entity_idx)
	return total

func get_entity_brush_count(entity_idx: int) -> int:
	return line_numbers[entity_idx][1].size()

func read_indices():
	var indices = []

	var is_inside_entity = false
	var is_inside_brush = false

	var line_number = 1
	for line in map_string:
		var first_char = line.substr(0, 1)

		if not is_inside_entity and not is_inside_brush:
			if first_char == "{":
				is_inside_entity = true
				indices.append([line_number, []])
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
				indices[-1][1].append(line_number)
			elif first_char == "}":
				is_inside_entity = false

		line_number += 1

	return indices

func read_entity_properties(entity_idx: int) -> Dictionary:
	var properties = {}

	var line_number = line_numbers[entity_idx][0]

	var parse = true
	while parse:
		var line = map_string[line_number]
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
		else:
			parse = false

		line_number += 1

	return properties

func read_entity_brush(entity_idx: int, brush_idx: int, valve_uvs: bool, bitmask_format: bool):
	var line_number = line_numbers[entity_idx][1][brush_idx]

	var brush_planes = []

	var parse = true
	while(parse):
		var line = map_string[line_number]

		if(line == null):
			parse = false
		elif(line_starts_with(line, '(')):
			brush_planes.append(parse_face(line, valve_uvs, bitmask_format))
		elif(line_starts_with(line, '}')):
			QodotUtil.debug_print('End of brush section')
			parse = false

		line_number += 1

	return QuakeBrush.new(brush_planes)

func parse_face(line: String, valve_uvs: bool, bitmask_format: int) -> QuakeFace:
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

	# Parse other stuff
	var loose_params = Array(line.substr(third_close_bracket + 2, line.length()).split(' '))
	QodotUtil.debug_print(['Loose params: ', loose_params])

	var texture = String(loose_params.pop_front())
	QodotUtil.debug_print(['Texture: ', texture])

	var uv = null
	if(valve_uvs):
		loose_params.pop_front()
		var u = PoolRealArray([
			loose_params.pop_front(),
			loose_params.pop_front(),
			loose_params.pop_front(),
			loose_params.pop_front()
		])
		loose_params.pop_front()
		loose_params.pop_front()
		var v = PoolRealArray([
			loose_params.pop_front(),
			loose_params.pop_front(),
			loose_params.pop_front(),
			loose_params.pop_front()
		])
		loose_params.pop_front()

		uv = PoolRealArray([
			u[0], u[1], u[2], u[3],
			v[0], v[1], v[2], v[3]
		])
	else:
		uv = PoolRealArray([loose_params.pop_front(), loose_params.pop_front()])

	QodotUtil.debug_print(['UV: ', uv])

	var rotation = float(loose_params.pop_front())
	QodotUtil.debug_print(['Rotation: ', rotation])

	var scale = Vector2(loose_params.pop_front(), loose_params.pop_front())
	QodotUtil.debug_print(['Scale: ', scale])

	var surface = -1
	var content = -1
	var color = -1
	var hexen_2_param = -1

	match bitmask_format:
		QodotEnums.BitmaskFormat.HEXEN_2:
			hexen_2_param = int(loose_params.pop_front())
			QodotUtil.debug_print(['Unknown Hexen 2 Parameter: ', hexen_2_param])

		QodotEnums.BitmaskFormat.QUAKE_2:
			if(loose_params.size() > 0):
				surface = int(loose_params.pop_front())
				QodotUtil.debug_print(['Surface: ', surface])

			if(loose_params.size() > 0):
				content = int(loose_params.pop_front())
				QodotUtil.debug_print(['Content: ', content])

		QodotEnums.BitmaskFormat.DAIKATANA:
			if(loose_params.size() > 0):
				surface = int(loose_params.pop_front())
				QodotUtil.debug_print(['Surface: ', surface])

			if(loose_params.size() > 0):
				content = int(loose_params.pop_front())
				QodotUtil.debug_print(['Content: ', content])

			if(loose_params.size() > 0):
				color = int(loose_params.pop_front())
				QodotUtil.debug_print(['Color: ', color])

	return QuakeFace.new(vertices, texture, uv, rotation, scale, surface, content, color, hexen_2_param)

func parse_vertex(vertex_substr: String) -> Vector3:
	var comps = vertex_substr.split(' ')
	return Vector3(comps[1], comps[2], comps[0])

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
