@tool
class_name QodotFGDSolidClass
extends QodotFGDClass

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
@export var spawn : String = QodotUtil.CATEGORY_STRING
@export var spawn_type: SpawnType = SpawnType.ENTITY

# Controls how visuals are built for this SolidClass
@export var visual_build: String = QodotUtil.CATEGORY_STRING
@export var build_visuals := true

# Controls how collisions are built for this SolidClass
@export var collision_build : String = QodotUtil.CATEGORY_STRING
@export var collision_shape_type: CollisionShapeType = CollisionShapeType.CONVEX

# The script file to associate with this SolidClass
# On building the map, this will be attached to any brush entities created
# via this classname
@export var scripting: String = QodotUtil.CATEGORY_STRING
@export var script_class: Script

func _init():
	prefix = "@SolidClass"
