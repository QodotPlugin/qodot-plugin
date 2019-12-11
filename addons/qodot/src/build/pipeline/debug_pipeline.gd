class_name QodotDebugPipeline

static func get_build_steps() -> Array:
	return [
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
