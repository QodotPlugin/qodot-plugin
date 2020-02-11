class_name QodotBuildEntityCenters
extends QodotBuildStep

func get_name() -> String:
	return "entity_centers"

func get_type() -> int:
	return self.Type.PER_ENTITY

func get_build_params() -> Array:
	return [
		'brush_data_dict'
	]

func _run(context) -> Dictionary:
	var entity_idx = context['entity_idx']
	var brush_data_dict = context['brush_data_dict']

	var brush_data = brush_data_dict[entity_idx]

	var entity_center = Vector3.ZERO
	for brush_idx in brush_data:
		var brush = create_brush_from_face_data(brush_data[brush_idx])
		entity_center += brush.center
	entity_center /= brush_data.size()

	return {
		'entity_centers': {
			entity_idx: entity_center
		}
	}
