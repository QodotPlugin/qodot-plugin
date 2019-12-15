class_name QodotBuildBrushAreas
extends QodotBuildCollision

func get_name() -> String:
	return "brush_areas"

func get_type() -> int:
	return self.Type.PER_BRUSH

func get_finalize_params() -> Array:
	return ['brush_areas']

func _run(context) -> Dictionary:
	var entity_idx = context['entity_idx']
	var brush_idx = context['brush_idx']
	var entity_properties = context['entity_properties']

	if not has_area_collision(entity_properties):
		return {}

	return {
		'nodes': {
			get_entity_key(entity_idx): {
				get_brush_key(brush_idx): {
					'collision_object': Area.new()
				}
			}
		}
	}
