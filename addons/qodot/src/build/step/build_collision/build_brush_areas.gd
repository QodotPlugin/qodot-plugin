class_name QodotBuildBrushAreas
extends QodotBuildCollision

func get_name() -> String:
	return "brush_areas"

func get_type() -> int:
	return self.Type.PER_BRUSH

func get_finalize_params() -> Array:
	return ['brush_areas']

func get_wants_finalize():
	return true

func _run(context) -> Dictionary:
	var entity_idx = context['entity_idx']
	var brush_idx = context['brush_idx']
	var entity_properties = context['entity_properties']

	if not has_area_collision(entity_properties):
		return {}

	return {
		'brush_areas': {
			entity_idx: {
				brush_idx: true
			}
		}
	}

func _finalize(context) -> Dictionary:
	var brush_areas = context['brush_areas']

	var brush_area_dict = {}

	for entity_idx in brush_areas:
		var entity_key = 'entity_' + String(entity_idx)

		if not entity_idx in brush_area_dict:
			brush_area_dict[entity_idx] = {}

		for brush_idx in brush_areas:
			var brush_collision_data = brush_areas[entity_idx][brush_idx]

			var brush_area = Area.new()
			brush_area.name = "CollisionObject"

			brush_area_dict[entity_key]['brush_' + String(brush_idx)] = brush_area

	return {
		'nodes': brush_area_dict
	}
