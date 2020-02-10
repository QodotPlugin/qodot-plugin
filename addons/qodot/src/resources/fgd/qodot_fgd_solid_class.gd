class_name QodotFGDSolidClass
extends QodotFGDClass
tool

enum SpawnType {
	WORLDSPAWN,
	MERGE_WORLDSPAWN,
	ENTITY
}

enum VisualBuildType {
	NONE,
	MATERIAL_MESHES,
	ATLASED_MESHES
}

enum PhysicsBodyType {
	NONE,
	AREA,
	STATIC_BODY,
	KINEMATIC_BODY,
	RIGID_BODY
}

enum CollisionShapeType {
	NONE,
	CONVEX,
	CONCAVE
}

# Controls whether a given SolidClass is the worldspawn, is combined with the worldspawn,
# or is spawned as its own free-standing entity
export(String) var spawn = QodotUtil.CATEGORY_STRING
export(SpawnType) var spawn_type = SpawnType.ENTITY

# Controls how visuals are built for this SolidClass
export(String) var visual_build = QodotUtil.CATEGORY_STRING
export(VisualBuildType) var visual_build_type = VisualBuildType.MATERIAL_MESHES

# Controls how collisions are built for this SolidClass
export(String) var collision_build = QodotUtil.CATEGORY_STRING
export(PhysicsBodyType) var physics_body_type = PhysicsBodyType.KINEMATIC_BODY
export(CollisionShapeType) var collision_shape_type = CollisionShapeType.CONVEX
export(bool) var merge_brush_collision = false

# The script file to associate with this SolidClass
# On building the map, this will be attached to any brush entities created
# via this classname
export(String) var scripting = QodotUtil.CATEGORY_STRING
export(Script) var script_class

func _init():
	prefix = "@SolidClass"
