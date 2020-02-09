class_name QodotBuildAreaConvexCollision
extends QodotBuildConvexCollisionShapes

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
	if not 'area_collision_shapes' in context:
		return {}

	var area_collision_shapes = context['area_collision_shapes']

	var area_collision_dict = {}


	for entity_key in area_collision_shapes:
		var area_collision_shape_key = entity_key + '_trigger'
		var brush_area = Area.new()
		brush_area.name = area_collision_shape_key
		var entity_center = Vector3.ZERO

		for brush_key in area_collision_shapes[entity_key]:
			var area_collision_shape_data = area_collision_shapes[entity_key][brush_key]
			var brush_center = area_collision_shape_data['brush_center']
			entity_center += brush_center
		entity_center /= area_collision_shapes.size()

		for brush_key in area_collision_shapes[entity_key]:
			var area_collision_shape_data = area_collision_shapes[entity_key][brush_key]

			var brush_center = area_collision_shape_data['brush_center']
			var brush_collision_vertices = area_collision_shape_data['brush_collision_vertices']

			var brush_collision_shape = create_convex_collision_shape(brush_collision_vertices)
			brush_collision_shape.name = brush_key
			brush_collision_shape.translation = brush_center - entity_center

			brush_area.add_child(brush_collision_shape)

		brush_area.translation = entity_center
		area_collision_dict[area_collision_shape_key] = brush_area

	return {
		'nodes': {
			'brush_entities_node': area_collision_dict
		}
	}
