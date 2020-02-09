class_name QodotSingleMeshAtlasedPipeline
extends QodotBuildPipeline

static func get_build_steps() -> Array:
	return [
		QodotBuildParseMap.new(),

		QodotBuildTextureList.new(),
		QodotBuildTextures.new(),
		QodotBuildTextureAtlas.new(),
		QodotBuildAtlasedMesh.new(),

		QodotBuildNode.new("static_body", "collision", StaticBody, ['worldspawn_node']),
		QodotBuildStaticConcaveCollisionSingle.new(),

		QodotBuildNode.new("brush_entities_node", "Brush Entities", QodotSpatial),
		QodotBuildAreaConvexCollision.new(),

		QodotBuildNode.new("point_entities_node", "Point Entities", QodotSpatial),
		QodotBuildPointEntities.new(),

		QodotBuildUnwrapUVs.new(),
	]
