class_name QuakeMapReader

# Utility class for parsing a quake .map file into a QuakeMap instance
# Separate from the import code to allow for runtime usage

const OPEN_BRACKET = "("
const CLOSE_BRACKET = ")"

func read_map_file(file: File) -> QuakeMap:
	QodotUtil.debug_print("Reading map file")
	var map_entities = []

	var parse = true
	while(parse):
		var line = read_line(file)

		if(line == null):
			parse = false
		elif(line.substr(0, 1) == "{"):
			map_entities.append(read_entity(file))

	return QuakeMap.new(map_entities)

func read_entity(file: File) -> QuakeEntity:
	QodotUtil.debug_print("Reading entity section")
	var entity_properties = {}
	var entity_brushes = []

	var parse = true
	while(parse):
		var line = read_line(file)

		if(line == null):
			parse = false
		elif(line_is_property(line)):
			var key = line_property_key(line)
			var val = line_property_value(line)

			match key:
				"origin":
					var val_comps = val.split(" ")
					entity_properties[key] = parse_point(val)
				"angle":
					entity_properties[key] = float(val)
				_:
					entity_properties[key] = val

			QodotUtil.debug_print([key, ": ", entity_properties[key]])
		elif(line_starts_with(line, "{")):
			entity_brushes.append(read_brush(file))
		elif(line_starts_with(line, "}")):
			QodotUtil.debug_print("End of entity section")
			parse = false

	return QuakeEntity.new(entity_properties, entity_brushes)

func read_brush(file: File) -> QuakeBrush:
	QodotUtil.debug_print("Reading brush section")
	var brush_planes = []

	var parse = true
	while(parse):
		var line = read_line(file)

		if(line == null):
			parse = false
		elif(line_starts_with(line, "(")):
			brush_planes.append(parse_plane(line))
		elif(line_starts_with(line, "}")):
			QodotUtil.debug_print("End of brush section")
			parse = false

	return QuakeBrush.new(brush_planes)

func parse_plane(line: String) -> QuakePlane:
	QodotUtil.debug_print(["Plane: ", line])

	# Parse points
	var first_open_bracket = line.find(OPEN_BRACKET, 0)
	var second_open_bracket = line.find(OPEN_BRACKET, first_open_bracket + 1)
	var third_open_bracket = line.find(OPEN_BRACKET, second_open_bracket + 1)

	var first_close_bracket = line.find(CLOSE_BRACKET, 0)
	var second_close_bracket = line.find(CLOSE_BRACKET, first_close_bracket + 1)
	var third_close_bracket = line.find(CLOSE_BRACKET, second_close_bracket + 1)

	var first_point = parse_point(line.substr(first_open_bracket + 2, first_close_bracket - first_open_bracket - 2))
	var second_point = parse_point(line.substr(second_open_bracket + 2, second_close_bracket - second_open_bracket - 2))
	var third_point = parse_point(line.substr(third_open_bracket + 2, third_close_bracket - third_open_bracket - 2))

	var points = [first_point, second_point, third_point]
	QodotUtil.debug_print(["Points: ", points])

	# Parse other stuff
	var loose_params = line.substr(third_close_bracket + 2, line.length()).split(" ")
	QodotUtil.debug_print(["Loose params: ", loose_params])

	var texture = String(loose_params[0])
	QodotUtil.debug_print(["Texture: ", texture])

	var uv = Vector2(loose_params[1], loose_params[2])
	QodotUtil.debug_print(["UV: ", uv])

	var rotation = float(loose_params[3])
	QodotUtil.debug_print(["Rotation: ", rotation])

	var scale = Vector2(loose_params[4], loose_params[5])
	QodotUtil.debug_print(["Scale: ", scale])

	return QuakePlane.new(points, texture, uv, rotation, scale)

func parse_point(point_substr: String) -> Vector3:
	var comps = point_substr.split(" ")
	return Vector3(comps[1], comps[2], comps[0])

func read_line(file: File):
	if(file.eof_reached()):
		QodotUtil.debug_print("EOF Reached")
		return null

	var line = file.get_line()
	QodotUtil.debug_print(line)
	if(line.substr(0, 2) == "//"):
		return read_line(file)
	return line

func line_starts_with(line: String, prefix: String):
	return line.substr(0, prefix.length()) == prefix

func escape_property_name(property_name):
	return "\"" + property_name + "\""

func line_is_property(line):
	return line_starts_with(line, "\"")

func line_property_key(line):
	return line.substr(1, line.find("\"", 1) - 1)

func line_property_value(line):
	var escaped_quote = "\""
	var first_quote = line.find(escaped_quote)
	var second_quote = line.find(escaped_quote, first_quote + 1)
	var third_quote = line.find(escaped_quote, second_quote + 1)
	var fourth_quote = line.find(escaped_quote, third_quote + 1)
	return line.substr(third_quote + 1, line.length() - (third_quote + 2))
