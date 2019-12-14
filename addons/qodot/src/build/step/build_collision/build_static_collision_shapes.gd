class_name QodotBuildStaticCollisionShapes
extends QodotBuildCollision

func get_name() -> String:
	return "static_collision_shapes"

func get_type() -> int:
	return self.Type.PER_BRUSH

func get_build_params() -> Array:
	return ['inverse_scale_factor']

func get_finalize_params() -> Array:
	return ['static_collision_shapes', 'inverse_scale_factor']

func get_wants_finalize():
	return true

func _run(context) -> Dictionary:
	var entity_idx = context['entity_idx']
	var brush_idx = context['brush_idx']
	var entity_properties = context['entity_properties']
	var brush_data = context['brush_data']
	var inverse_scale_factor = context['inverse_scale_factor']

	if not has_static_collision(entity_properties):
		return {}

	var map_reader = QuakeMapReader.new()
	var brush = map_reader.create_brush(brush_data)

	var collision_vertices = get_brush_collision_vertices(entity_properties, brush, true)
	var scaled_collision_vertices = PoolVector3Array()
	for collision_vertex in collision_vertices:
		scaled_collision_vertices.append(collision_vertex / inverse_scale_factor)

	return {
		'static_collision_shapes': {
			'Entity' + String(entity_idx) + '_Brush' + String(brush_idx) + '_Collision': {
				'brush_center': brush.center,
				'brush_collision_vertices': scaled_collision_vertices
			}
		}
	}

func _finalize(context) -> Dictionary:
	var static_collision_shapes = context['static_collision_shapes']
	var inverse_scale_factor = context['inverse_scale_factor']

	QodotPrinter.print_typed(static_collision_shapes)

	var brush_collision_dict = {}

	for brush_collision_key in static_collision_shapes:
		var static_collision_shape = static_collision_shapes[brush_collision_key]

		var brush_center = static_collision_shape['brush_center']
		var brush_collision_vertices = static_collision_shape['brush_collision_vertices']

		var brush_convex_collision = ConvexPolygonShape.new()
		brush_convex_collision.set_points(brush_collision_vertices)

		var brush_collision_shape = CollisionShape.new()
		brush_collision_shape.name = brush_collision_key
		brush_collision_shape.translation = brush_center / inverse_scale_factor
		brush_collision_shape.set_shape(brush_convex_collision)

		brush_collision_dict[brush_collision_key] = brush_collision_shape

	return {
		'nodes': {
			'collision': {
				'static_body': brush_collision_dict
			}
		}
	}
