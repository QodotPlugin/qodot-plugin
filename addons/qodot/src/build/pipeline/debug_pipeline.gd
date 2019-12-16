class_name QodotDebugPipeline
extends QodotBuildPipeline

static func get_build_steps() -> Array:
	return [
		QodotBuildParseMap.new(),
		QodotBuildTextureList.new(),
		QodotBuildMaterials.new(),

		QodotBuildEntityNodes.new(),
		QodotBuildBrushNodes.new(),

		QodotBuildBrushStaticBodies.new(),
		QodotBuildBrushAreas.new(),
		QodotBuildBrushConvexCollision.new(),

		QodotBuildBrushFaceAxes.new(),
		QodotBuildBrushFaceVertices.new(),
		QodotBuildBrushFaceMeshes.new(),

		QodotBuildNode.new("entity_spawns", "Entity Spawns"),
		QodotBuildEntitySpawns.new()
	]
