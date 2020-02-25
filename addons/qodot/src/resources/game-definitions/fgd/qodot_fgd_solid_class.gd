class_name QodotFGDSolidClass
extends QodotFGDClass
tool

enum SpawnType {
	WORLDSPAWN = 0,
	MERGE_WORLDSPAWN = 1,
	ENTITY = 2,
	GROUP = 3
}

enum CollisionShapeType {
	NONE,
	CONVEX,
	CONCAVE
}

# Controls whether a given SolidClass is the worldspawn, is combined with the worldspawn,
# or is spawned as its own free-standing entity
export(String) var spawn : String = QodotUtil.CATEGORY_STRING
export(SpawnType) var spawn_type : int = SpawnType.ENTITY

# Controls how visuals are built for this SolidClass
export(String) var visual_build : String = QodotUtil.CATEGORY_STRING
export(bool) var build_visuals := true

# Controls how collisions are built for this SolidClass
export(String) var collision_build : String = QodotUtil.CATEGORY_STRING
export(CollisionShapeType) var collision_shape_type : int = CollisionShapeType.CONVEX

# The script file to associate with this SolidClass
# On building the map, this will be attached to any brush entities created
# via this classname
export(String) var scripting : String = QodotUtil.CATEGORY_STRING
export(Script) var script_class : Script

func _init() -> void:
	prefix = "@SolidClass"
