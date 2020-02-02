class_name QodotPointEntityDefinition
extends Resource
tool

## A node used to define an entity in a QodotEntityDefinitionSet
export(String) var classname

# description for the entity def
export var description = ""

# the colour of the entity def
export var color = Color(0.8, 0.8, 0.8)

# the size of the entity def, it gets expressed as two extent points
export var size_point_1 = Vector3(-8, -8, -8)
export var size_point_2 = Vector3(8, 8, 8) 

# the scene file you want to associate with this entity definition
# on building the map, an instanced node of this scene will be added
# to the map
export(String, FILE, '*.tscn,*.scn') var scene_file


func build_def_text() -> String:
	var res = "@PointClass size(%s %s %s, %s %s %s) color(%s %s %s) = %s" % [int(size_point_1.x), int(size_point_1.y), int(size_point_1.z), int(size_point_2.x), int(size_point_2.y), int(size_point_2.z), color.r8, color.g8, color.b8, classname]
	#I have a weird feeling that Godot uses "\n" new lines internally, so just using \n here is right? Uncertain.
	var normalized_description = description.replace("\n", " ").strip_edges() 
	if normalized_description != "":
		res += " : \"%s\"%s" % [normalized_description, QodotUtil.newline()]
	res += "[" + QodotUtil.newline()
	res += "\tangle(float) : \"0.0\"" + QodotUtil.newline()
	#eventually custom properties would go here!
	res += "]" + QodotUtil.newline()

	return res

