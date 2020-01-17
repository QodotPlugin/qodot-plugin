class_name QodotEntityDefinition
extends QodotSpatial
tool

## A node used to define an entity in a QodotEntityDefinitionSet

# description for the entity def
export var description = ""

# the colour of the entity def
export var color = Color(0.8, 0.8, 0.8)

# the size of the entity def, it gets expressed as two extent points
export var size_pt1 = Vector3(-8, -8, -8)
export var size_pt2 = Vector3(8, 8, 8) 

# the scene file you want to associate with this entity definition
# on building the map, an instanced node of this scene will be added
# to the map
export(String, FILE, '*.tscn,*.scn') var scene_file

#an override for the entity classname, is the name of this node by default
export(String) var class_name_override

func determine_entity_class_name() -> String:
	if class_name_override != null:
		var stripped_override = class_name_override.strip_edges()
		if stripped_override != "":
			return stripped_override
	return name

func build_def_text() -> String:
	var res = "@PointClass size(%s %s %s, %s %s %s) color(%s %s %s) = %s" % [int(size_pt1.x), int(size_pt1.y), int(size_pt1.z), int(size_pt2.x), int(size_pt2.y), int(size_pt2.z), color.r8, color.g8, color.b8, determine_entity_class_name()]
	var normalized_description = description.replace("\n", " ").strip_edges()
	if normalized_description != "":
		res += " : \"%s\"\n" % normalized_description
	res += "[\n"
	res += "\tangle(float) : \"0.0\"\n"
	#eventually custom properties would go here!
	res += "]\n"

	return res

