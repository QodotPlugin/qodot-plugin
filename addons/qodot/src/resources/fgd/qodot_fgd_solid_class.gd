class_name QodotFGDSolidClass
extends QodotFGDClass
tool

func _init():
	prefix = "@SolidClass"

# The script file to associate with this SolidClass
# On building the map, this will be attached to any brush entities created
# via this classname
export(Script) var script_class
