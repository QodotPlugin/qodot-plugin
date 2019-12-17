class_name QodotBuildStaticConcaveCollisionPerEntity
extends QodotBuildConcaveCollisionShapes

func get_name() -> String:
	return 'static_concave_collision_per_entity'

func get_finalize_params() -> Array:
	return ['static_concave_collision']

func get_wants_finalize():
	return true

func get_context_key():
	return 'static_concave_collision'

func should_spawn_collision_shapes(entity_properties):
	return has_static_collision(entity_properties)

func _finalize(context) -> Dictionary:
	var static_concave_collision = context['static_concave_collision']

	var static_collision_dict = {}

	for entity_key in static_concave_collision:
		var entity_triangles = PoolVector3Array()
		for brush_key in static_concave_collision[entity_key]:
			var static_collision_shape = static_concave_collision[entity_key][brush_key]
			var brush_collision_triangles = static_collision_shape['brush_collision_triangles']
			for vertex in brush_collision_triangles:
				entity_triangles.append(vertex)

		var entity_collision_shape = create_concave_collision_shape(entity_triangles)
		entity_collision_shape.name = entity_key + '_collision'
		static_collision_dict[entity_key] = entity_collision_shape

	return {
		'nodes': {
			'collision_node': {
				'static_body': static_collision_dict
			}
		}
	}
