class_name QodotBuildAreaCollisionShapes
extends QodotBuildCollisionShapes

func get_name() -> String:
	return 'area_collision_shapes'

func get_finalize_params() -> Array:
	return ['area_collision_shapes']

func get_wants_finalize():
	return true

func get_context_key():
	return 'area_collision_shapes'

func should_spawn_collision_shapes(entity_properties):
	return has_area_collision(entity_properties)

func _finalize(context) -> Dictionary:
	var area_collision_shapes = context['area_collision_shapes']

	var area_collision_dict = {}

	for area_collision_shape_key in area_collision_shapes:
		var area_collision_shape_data = area_collision_shapes[area_collision_shape_key]

		var brush_center = area_collision_shape_data['brush_center']
		var brush_collision_vertices = area_collision_shape_data['brush_collision_vertices']

		var brush_collision_shape = create_convex_collision_shape(brush_collision_vertices)

		var brush_area = Area.new()
		brush_area.name = area_collision_shape_key + "_Trigger"
		brush_area.translation = brush_center
		brush_area.add_child(brush_collision_shape)

		area_collision_dict[area_collision_shape_key] = brush_area

	return {
		'nodes': {
			'collision': area_collision_dict
		}
	}
