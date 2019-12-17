class_name QodotBuildStaticConvexCollisionPerBrush
extends QodotBuildConvexCollisionShapes

func get_name() -> String:
	return 'static_convex_collision_per_brush'

func get_finalize_params() -> Array:
	return ['static_convex_collision']

func get_wants_finalize():
	return true

func get_context_key():
	return 'static_convex_collision'

func should_spawn_collision_shapes(entity_properties):
	return has_static_collision(entity_properties)

func _finalize(context) -> Dictionary:
	var static_convex_collision = context['static_convex_collision']

	var static_collision_dict = {}

	for entity_idx in static_convex_collision:
		for brush_idx in static_convex_collision[entity_idx]:
			var brush_collision_key = entity_idx + '_' + brush_idx + '_collision'
			var static_collision_shape = static_convex_collision[entity_idx][brush_idx]

			var brush_center = static_collision_shape['brush_center']
			var brush_collision_vertices = static_collision_shape['brush_collision_vertices']

			var brush_collision_shape = create_convex_collision_shape(brush_collision_vertices)
			brush_collision_shape.name = brush_collision_key
			brush_collision_shape.translation = brush_center

			static_collision_dict[brush_collision_key] = brush_collision_shape

	return {
		'nodes': {
			'collision_node': {
				'static_body': static_collision_dict
			}
		}
	}
