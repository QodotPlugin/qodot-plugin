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

func _run(context):
	var entity_idx = context['entity_idx']
	var brush_idx = context['brush_idx']
	var entity_properties = context['entity_properties']

	if not 'classname' in entity_properties:
		return null

	if entity_properties['classname'].find('trigger') == -1 and entity_properties['classname'] != 'func_illusionary':
		return null

	return ["nodes", get_brush_attach_path(entity_idx, brush_idx), [], entity_properties]

func _finalize(context) -> void:
	var brush_areas = context['brush_areas']

	for brush_collision_idx in range(0, brush_areas.size()):
		var brush_collision_data = brush_areas[brush_collision_idx]

		var entity_properties = brush_collision_data[3]
		var brush_area = Area.new()
		brush_area.name = "CollisionObject"

		brush_areas[brush_collision_idx][2] = [brush_area]
