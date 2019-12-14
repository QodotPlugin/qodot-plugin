class_name QodotBuildMeshNode
extends QodotBuildStep

func get_name() -> String:
	return "mesh_node"

func get_type() -> int:
	return self.Type.SINGLE

func _run(context) -> Dictionary:
	var mesh_node = QodotNode.new()
	mesh_node.name = "Meshes"

	return {
		'nodes': {
			'meshes': mesh_node
		}
	}
