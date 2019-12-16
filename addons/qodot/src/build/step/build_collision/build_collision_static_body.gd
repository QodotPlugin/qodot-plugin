class_name QodotBuildCollisionStaticBody
extends QodotBuildStep

func get_name() -> String:
	return "collision_static_body"

func get_type() -> int:
	return self.Type.SINGLE

func _run(context) -> Dictionary:
	return {
		'nodes': {
			'collision_node': {
				'static_body': StaticBody.new()
			}
		}
	}
