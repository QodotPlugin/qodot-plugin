class_name QodotSingleMeshAtlasedPipeline
extends QodotBuildPipeline

static func get_build_steps() -> Array:
	return [
		QodotBuildParseMap.new(),

		QodotBuildTextureList.new(),
		QodotBuildTextures.new(),
		QodotBuildTextureAtlas.new(),
		QodotBuildAtlasedMesh.new(),

		QodotBuildNode.new("collision_node", "Collision", QodotSpatial),
		QodotBuildNode.new("static_body", "Static Collision", StaticBody, ['collision_node']),
		QodotBuildStaticConcaveCollisionSingle.new(),

		QodotBuildNode.new("triggers_node", "Triggers", QodotSpatial),
		QodotBuildAreaConvexCollision.new(),

		QodotBuildNode.new("entity_spawns_node", "Entity Spawns", QodotSpatial),
		QodotBuildEntitySpawns.new(),

		QodotBuildUnwrapUVs.new(),
	]
