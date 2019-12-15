class_name QodotBuildStaticCollisionShapes
extends QodotBuildCollision

func get_name() -> String:
	return "static_collision_shapes"

func get_type() -> int:
	return self.Type.PER_BRUSH

func get_finalize_params() -> Array:
	return ['static_collision_shapes']

func get_wants_finalize():
	return true

func _run(context) -> Dictionary:
	var entity_idx = context['entity_idx']
	var brush_idx = context['brush_idx']
	var entity_properties = context['entity_properties']
	var brush_data = context['brush_data']

	if not has_static_collision(entity_properties):
		return {}

	var brush = create_brush_from_face_data(brush_data)

	return {
		'static_collision_shapes': {
			get_entity_brush_key(entity_idx, brush_idx): {
				'brush_center': brush.center,
				'brush_collision_vertices': get_brush_collision_vertices(entity_properties, brush, true)
			}
		}
	}

func _finalize(context) -> Dictionary:
	var static_collision_shapes = context['static_collision_shapes']

	var brush_collision_dict = {}

	for brush_collision_key in static_collision_shapes:
		var static_collision_shape = static_collision_shapes[brush_collision_key]

		var brush_center = static_collision_shape['brush_center']
		var brush_collision_vertices = static_collision_shape['brush_collision_vertices']

		var brush_convex_collision = ConvexPolygonShape.new()
		brush_convex_collision.set_points(brush_collision_vertices)

		var brush_collision_shape = CollisionShape.new()
		brush_collision_shape.name = brush_collision_key
		brush_collision_shape.translation = brush_center
		brush_collision_shape.set_shape(brush_convex_collision)

		brush_collision_dict[brush_collision_key] = brush_collision_shape

	return {
		'nodes': {
			'collision': {
				'static_body': brush_collision_dict
			}
		}
	}
