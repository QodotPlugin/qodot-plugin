class_name QodotBuildAreaConvexCollision
extends QodotBuildConvexCollisionShapes

func get_name() -> String:
	return 'area_collision_shapes'

func get_finalize_params() -> Array:
	return ['entity_definition_set', 'entity_properties_array', 'area_collision_shapes']

func get_wants_finalize():
	return true

func get_context_key():
	return 'area_collision_shapes'

func should_spawn_collision_shapes(entity_definition_set: Dictionary, entity_properties: Dictionary) -> bool:
	return has_brush_entity_collision(entity_definition_set, entity_properties)

func _finalize(context) -> Dictionary:
	if not 'area_collision_shapes' in context:
		return {}

	var area_collision_shapes = context['area_collision_shapes']
	var entity_definition_set = context['entity_definition_set']
	var entity_properties_array = context['entity_properties_array']

	var area_collision_dict = {}

	for entity_idx in area_collision_shapes:
		var entity_properties = entity_properties_array[entity_idx]
		if not 'classname' in entity_properties:
			continue

		var classname = entity_properties['classname']
		var entity_definition = entity_definition_set[classname]

		if not entity_definition is QodotFGDSolidClass:
			continue

		var brush_collision = null

		match(entity_definition.collision_type):
			QodotFGDSolidClass.SolidClassCollisionType.AREA:
				brush_collision = Area.new()
			QodotFGDSolidClass.SolidClassCollisionType.STATIC_BODY:
				brush_collision = StaticBody.new()
			QodotFGDSolidClass.SolidClassCollisionType.KINEMATIC_BODY:
				brush_collision = KinematicBody.new()
			QodotFGDSolidClass.SolidClassCollisionType.RIGID_BODY:
				brush_collision = RigidBody.new()
			_:
				continue

		brush_collision.name = 'collision'
		var entity_center = Vector3.ZERO

		for brush_idx in area_collision_shapes[entity_idx]:
			var area_collision_shape_data = area_collision_shapes[entity_idx][brush_idx]
			var brush_center = area_collision_shape_data['brush_center']
			entity_center += brush_center
		entity_center /= area_collision_shapes[entity_idx].size()

		for brush_idx in area_collision_shapes[entity_idx]:
			var area_collision_shape_data = area_collision_shapes[entity_idx][brush_idx]

			var brush_center = area_collision_shape_data['brush_center']
			var brush_collision_vertices = area_collision_shape_data['brush_collision_vertices']

			var brush_collision_shape = create_convex_collision_shape(brush_collision_vertices)
			brush_collision_shape.name = get_brush_key(brush_idx)
			brush_collision_shape.translation = brush_center - entity_center

			brush_collision.add_child(brush_collision_shape)

		area_collision_dict[get_entity_key(entity_idx)] = {
			'worldspawn_node': brush_collision
		}

	return {
		'nodes': {
			'brush_entities_node': area_collision_dict
		}
	}
