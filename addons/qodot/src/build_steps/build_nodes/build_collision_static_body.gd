class_name QodotBuildCollisionStaticBody
extends QodotBuildStep

func get_name() -> String:
	return "collision_static_body"

func get_type() -> int:
	return self.Type.SINGLE

func _run(context) -> Array:
	var static_body_node = StaticBody.new()
	return ["nodes", "./Collision", [static_body_node]]
