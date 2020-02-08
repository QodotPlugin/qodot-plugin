class_name QodotFGDPointClass
extends QodotFGDClass
tool

func _init():
	prefix = "@PointClass"

# The scene file to associate with this PointClass
# On building the map, this scene will be instanced into the scene tree
export(String, FILE, '*.tscn,*.scn') var scene_file

# The script file to associate with this PointClass
# On building the map, this will be attached to any brush entities created
# via this classname if no scene_file is specified
export(Script) var script_class
