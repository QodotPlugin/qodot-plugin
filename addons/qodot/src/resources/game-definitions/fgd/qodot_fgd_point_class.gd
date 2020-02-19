class_name QodotFGDPointClass
extends QodotFGDClass
tool

func _init() -> void:
	prefix = "@PointClass"

export(String) var scene : String = QodotUtil.CATEGORY_STRING

# The scene file to associate with this PointClass
# On building the map, this scene will be instanced into the scene tree
export(PackedScene) var scene_file : PackedScene

export(String) var scripting : String = QodotUtil.CATEGORY_STRING

# The script file to associate with this PointClass
# On building the map, this will be attached to any brush entities created
# via this classname if no scene_file is specified
export(Script) var script_class : Script
