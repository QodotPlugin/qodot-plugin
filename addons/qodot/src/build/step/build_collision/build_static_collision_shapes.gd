class_name QodotBuildStaticCollisionShapes
extends QodotBuildCollisionShapes

func get_name() -> String:
	return 'static_collision_shapes'

func get_finalize_params() -> Array:
	return ['static_collision_shapes']

func get_wants_finalize():
	return true

func get_context_key():
	return 'static_collision_shapes'

func should_spawn_collision_shapes(entity_properties):
	return has_static_collision(entity_properties)

func _finalize(context) -> Dictionary:
	var static_collision_shapes = context['static_collision_shapes']

	var static_collision_dict = {}

	for brush_collision_key in static_collision_shapes:
		var static_collision_shape = static_collision_shapes[brush_collision_key]

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
