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
		QodotBuildBrushConvexCollision.new(),

		QodotBuildBrushFaceAxes.new(),
		QodotBuildBrushFaceVertices.new(),
		QodotBuildBrushFaceMeshes.new(),

		QodotBuildNode.new("point_entities_node", "Point Entities"),
		QodotBuildPointEntities.new()
	]
