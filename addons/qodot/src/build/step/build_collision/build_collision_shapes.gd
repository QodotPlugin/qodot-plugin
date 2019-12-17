class_name QodotBuildCollisionShapes
extends QodotBuildCollision

func get_name() -> String:
	return 'collision_shapes'

func get_type() -> int:
	return self.Type.PER_BRUSH

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
					'brush_center': brush.center,
					'brush_collision_vertices': get_brush_collision_vertices(entity_properties, brush, true)
				}
			}
		}
	}

func get_context_key() -> String:
	return 'collision_shapes'

func should_spawn_collision_shapes(entity_properties) -> bool:
	return false
