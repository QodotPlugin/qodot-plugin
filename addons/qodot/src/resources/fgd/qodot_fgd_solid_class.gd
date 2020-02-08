class_name QodotFGDSolidClass
extends QodotFGDClass
tool

func _init():
	prefix = "@SolidClass"

# The script file to associate with this SolidClass
# On building the map, this will be attached to any brush entities created
# via this classname
export(Script) var script_class

# If set to true, brush entities with this class will be
# combined with the worldspawn during geometry generation
# (Works like func_group)
export(bool) var is_worldspawn = false
