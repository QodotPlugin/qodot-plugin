class_name QodotMeshPerMaterialPipeline
extends QodotBuildPipeline

static func get_build_steps() -> Array:
	return [
		QodotBuildMeshNode.new(),
		QodotBuildMaterialMeshes.new(),

		QodotBuildCollisionNode.new(),
		QodotBuildCollisionStaticBody.new(),
		QodotBuildStaticCollisionShapes.new(),
		QodotBuildAreaCollisionShapes.new()
	]
