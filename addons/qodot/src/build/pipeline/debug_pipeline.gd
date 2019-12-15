class_name QodotDebugPipeline
extends QodotBuildPipeline

static func get_build_steps() -> Array:
	return [
		QodotBuildParseMap.new(),
		QodotBuildTextureList.new(),
		QodotBuildMaterials.new(),

		QodotBuildEntityNodes.new(),
		QodotBuildEntitySpawns.new(),

		QodotBuildBrushNodes.new(),

		QodotBuildBrushStaticBodies.new(),
		QodotBuildBrushAreas.new(),
		QodotBuildBrushCollisionShapes.new(),

		QodotBuildBrushFaceAxes.new(),
		QodotBuildBrushFaceVertices.new(),
		QodotBuildBrushFaceMeshes.new()
	]
