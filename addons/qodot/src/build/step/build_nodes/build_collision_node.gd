class_name QodotBuildCollisionNode
extends QodotBuildStep

func get_name() -> String:
	return "collision_node"

func get_type() -> int:
	return self.Type.SINGLE

func _run(context) -> Dictionary:
	var collision_node = QodotNode.new()
	collision_node.name = "Collision"
	return {
		'nodes': {
			'collision': collision_node
		}
	}
