class_name QodotBuildStaticConcaveCollisionSingle
extends QodotBuildConcaveCollisionShapes

func get_name() -> String:
	return 'static_concave_collision_single'

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

	var collision_triangles = PoolVector3Array()
	for entity_idx in static_concave_collision:
		for brush_idx in static_concave_collision[entity_idx]:
			var static_collision_shape = static_concave_collision[entity_idx][brush_idx]
			var brush_collision_triangles = static_collision_shape['brush_collision_triangles']
			for vertex in brush_collision_triangles:
				collision_triangles.append(vertex)

	var brush_collision_shape = create_concave_collision_shape(collision_triangles)

	return {
		'nodes': {
			'collision_node': {
				'static_body': {
					'convex_collision': brush_collision_shape
				}
			}
		}
	}
