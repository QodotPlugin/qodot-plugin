class_name QodotBuildBrushCollisionShapes
extends QodotBuildCollision

func get_name() -> String:
	return "brush_collision_shapes"

func get_type() -> int:
	return self.Type.PER_BRUSH

func get_build_params() -> Array:
	return ['inverse_scale_factor']

func get_finalize_params() -> Array:
	return ['brush_collision_shapes']

func get_wants_finalize():
	return false

func _run(context) -> Dictionary:
	var entity_idx = context['entity_idx']
	var brush_idx = context['brush_idx']
	var entity_properties = context['entity_properties']
	var brush_data = context['brush_data']
	var inverse_scale_factor = context['inverse_scale_factor']

	var map_reader = QuakeMapReader.new()
	var brush = map_reader.create_brush(brush_data)

	var collision_vertices = get_brush_collision_vertices(entity_properties, brush)
	var scaled_collision_vertices = PoolVector3Array()
	for collision_vertex in collision_vertices:
		scaled_collision_vertices.append(collision_vertex / inverse_scale_factor)

	var brush_convex_collision = ConvexPolygonShape.new()
	brush_convex_collision.set_points(scaled_collision_vertices)

	var brush_collision_shape = CollisionShape.new()
	brush_collision_shape.set_shape(brush_convex_collision)

	return {
		'brush_collision_shapes': {
			entity_idx: {
				brush_idx: {
					'entity_properties': entity_properties,
					'brush_collision_vertices': scaled_collision_vertices
				}
			}
		},
		'nodes': {
			'entity_' + String(entity_idx): {
				'brush_' + String(brush_idx): {
					'collision_object': {
						'collision_shape': brush_collision_shape
					}
				}
			}
		}
	}

func _finalize(context) -> Dictionary:
	var brush_collision_shapes = context['brush_collision_shapes']

	var brush_collision_dict = {}

	for entity_idx in brush_collision_shapes:
		var entity_key = 'entity_' + String(entity_idx)

		if not entity_key in brush_collision_dict:
			brush_collision_dict[entity_key] = {}

		for brush_idx in brush_collision_shapes[entity_idx]:
			var brush_collision_data = brush_collision_shapes[entity_idx][brush_idx]

			var entity_properties = brush_collision_data['entity_properties']
			var brush_collision_vertices = brush_collision_data['brush_collision_vertices']

			var brush_convex_collision = ConvexPolygonShape.new()
			brush_convex_collision.set_points(brush_collision_vertices)

			var brush_collision_shape = CollisionShape.new()
			brush_collision_shape.set_shape(brush_convex_collision)

			brush_collision_dict[entity_key]['brush_' + String(brush_idx)] = {
				'static_body': {
					'collision_shape': brush_collision_shape
				}
			}

	return {
		'nodes': brush_collision_dict
	}
