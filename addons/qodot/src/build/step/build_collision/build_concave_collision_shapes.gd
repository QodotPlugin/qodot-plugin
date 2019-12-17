class_name QodotBuildConcaveCollisionShapes
extends QodotBuildCollisionShapes

func get_name() -> String:
	return 'concave_collision_shapes'

func _run(context) -> Dictionary:
	var entity_idx = context['entity_idx']
	var brush_idx = context['brush_idx']
	var brush_data = context['brush_data']
	var entity_properties = context['entity_properties']

	if not should_spawn_collision_shapes(entity_properties):
		return {}

	var brush = create_brush_from_face_data(brush_data)

	return {
		get_context_key(): {
			get_entity_key(entity_idx): {
				get_brush_key(brush_idx): {
					'brush_collision_triangles': get_brush_collision_triangles(brush, true)
				}
			}
		}
	}

func get_context_key() -> String:
	return 'concave_collision_shapes'

func create_concave_collision_shape(triangles: PoolVector3Array) -> CollisionShape:
	var concave_polygon = ConcavePolygonShape.new()
	concave_polygon.set_faces(triangles)

	var brush_collision_shape = CollisionShape.new()
	brush_collision_shape.set_shape(concave_polygon)

	return brush_collision_shape
