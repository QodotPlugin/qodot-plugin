class_name QodotSingleMeshAtlasedPipeline
extends QodotBuildPipeline

static func get_build_steps() -> Array:
	return [
		QodotBuildMaterials.new(),
		QodotBuildTextureAtlas.new(),

		QodotBuildMeshNode.new(),
		QodotBuildAtlasedMesh.new(),

		QodotBuildCollisionNode.new(),
		QodotBuildCollisionStaticBody.new(),
		QodotBuildStaticCollisionShapes.new(),
		QodotBuildAreaCollisionShapes.new()
	]
