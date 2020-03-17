class_name QodotWorldspawnLayer
extends Resource

export(String) var name := ""
export(String) var texture := ""
export(String) var node_class := ""
export(bool) var build_visuals := true
export(QodotFGDSolidClass.CollisionShapeType) var collision_shape_type := QodotFGDSolidClass.CollisionShapeType.CONVEX
export(Script) var script_class = null

func _init() -> void:
	resource_name = "Worldspawn Layer"
