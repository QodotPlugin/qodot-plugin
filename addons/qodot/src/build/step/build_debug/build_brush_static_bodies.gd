class_name QodotBuildBrushStaticBodies
extends QodotBuildCollision

func get_name() -> String:
	return "brush_static_bodies"

func get_type() -> int:
	return self.Type.PER_BRUSH

func get_finalize_params() -> Array:
	return ['brush_static_bodies']

func _run(context):
	var entity_idx = context['entity_idx']
	var brush_idx = context['brush_idx']
	var entity_properties = context['entity_properties']

	if not has_static_collision(entity_properties):
		return null

	var static_body = StaticBody.new()

	return {
		'nodes': {
			get_entity_key(entity_idx): {
				get_brush_key(brush_idx): {
					'collision_object': static_body
				}
			}
		}
	}
