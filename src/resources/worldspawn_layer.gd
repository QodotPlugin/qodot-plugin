class_name QodotWorldspawnLayer
extends Resource

@export var name := ""
@export var texture := ""
@export var node_class := ""
@export var build_visuals := true
@export var collision_shape_type: QodotFGDSolidClass.CollisionShapeType = QodotFGDSolidClass.CollisionShapeType.CONVEX # (QodotFGDSolidClass.CollisionShapeType)
@export var script_class: Script = null

func _init():
	resource_name = "Worldspawn Layer"
