class_name QodotBuildStaticConcaveCollisionPerBrush
extends QodotBuildConcaveCollisionShapes

func get_name() -> String:
	return 'static_concave_collision_per_brush'

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
		for brush_key in static_concave_collision[entity_key]:
			var entity_brush_key = entity_key + '_' + brush_key

			var static_collision_shape = static_concave_collision[entity_key][brush_key]
			var brush_collision_triangles = static_collision_shape['brush_collision_triangles']

			var brush_collision_shape = create_concave_collision_shape(brush_collision_triangles)
			brush_collision_shape.name = entity_brush_key + '_collision'
			static_collision_dict[entity_brush_key] = brush_collision_shape

	return {
		'nodes': {
			'collision_node': {
				'static_body': static_collision_dict
			}
		}
	}
