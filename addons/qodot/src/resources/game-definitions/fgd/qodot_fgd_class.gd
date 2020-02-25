class_name QodotFGDClass
extends Resource

var prefix: String = ""

export(String) var class_options : String = QodotUtil.CATEGORY_STRING

export(String) var classname := ""

export(String) var description := ""

export(bool) var qodot_internal := false

export(Array, Resource) var base_classes := []

export(Dictionary) var class_properties := {}

export(Dictionary) var class_property_descriptions := {}

export(Dictionary) var meta_properties := {
	"size": AABB(Vector3(-8, -8, -8), Vector3(8, 8, 8)),
	"color": Color(0.8, 0.8, 0.8)
}

export(String) var node_options : String = QodotUtil.CATEGORY_STRING

export(String) var node_class := ""

export(bool) var transient_node := false

func build_def_text() -> String:
	# Class prefix
	var res : String = prefix

	# Meta properties
	var base_str = ""
	var meta_props = meta_properties.duplicate()

	for base_class in base_classes:
		if not 'classname' in base_class:
			continue

		base_str += base_class.classname

		if base_class != base_classes.back():
			base_str += ", "

	if base_str != "":
		meta_props['base'] = base_str

	for prop in meta_props:
		var value = meta_props[prop]
		res += " " + prop + "("

		if value is AABB:
			res += "%s %s %s, %s %s %s" % [
				value.position.x,
				value.position.y,
				value.position.z,
				value.size.x,
				value.size.y,
				value.size.z
			]
		elif value is Color:
			res += "%s %s %s" % [
				value.r8,
				value.g8,
				value.b8
			]
		elif value is String:
			res += value

		res += ")"

	res += " = " + classname

	var normalized_description = description.replace("\n", " ").strip_edges()
	if normalized_description != "":
		res += " : \"%s\" " % [normalized_description]

	res += "[" + QodotUtil.newline()

	# Class properties
	for prop in class_properties:
		var value = class_properties[prop]

		var prop_val = null
		var prop_type := ""
		var prop_description: String = class_property_descriptions[prop] if prop in class_property_descriptions else ""

		if value is int:
			prop_type = "integer"
			prop_val = String(value)
		elif value is float:
			prop_type = "float"
			prop_val = String(value)
		elif value is String:
			prop_type = "string"
			prop_val = "\"" + value + "\""
		elif value is Vector3:
			prop_type = "string"
			prop_val = "\"%s %s %s\"" % [
				value.x,
				value.y,
				value.z
			]
		elif value is Color:
			prop_type = "color255"
			prop_val = "\"%s %s %s\"" % [
				value.r8,
				value.g8,
				value.b8
			]
		elif value is Dictionary:
			prop_type = "choices"
			prop_val = "[" + "\n"
			for choice in value:
				var choice_val = value[choice]
				prop_val += "\t\t" + String(choice_val) + " : \"" + choice + "\"\n"
			prop_val += "\t]"
		elif value is Array:
			prop_type = "flags"
			prop_val = "[" + "\n"
			for arr_val in value:
				prop_val += "\t\t" + String(arr_val[1]) + " : \"" + String(arr_val[0]) + "\" : " + ("1" if arr_val[2] else "0") + "\n"
			prop_val += "\t]"
		elif value is NodePath:
			prop_type = "target_destination"
		elif value is Object:
			prop_type = "target_source"

		if(prop_val):
			res += "\t"
			res += prop
			res += "("
			res += prop_type
			res += ")"

			if not value is Array:
				res += " : \""
				res += prop_description
				res += "\" "

			if value is Dictionary or value is Array:
				res += " = "
			else:
				res += " : "

			res += prop_val
			res += QodotUtil.newline()

	res += "]" + QodotUtil.newline()

	return res

