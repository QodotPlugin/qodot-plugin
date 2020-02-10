class_name QodotBuildBrushEntityCollisionShapes
extends QodotBuildCollision

func get_name() -> String:
	return 'brush_entity_collision_shapes'

func get_wants_finalize():
	return true
	
func get_finalize_params() -> Array:
	return ['entity_definition_set', 'entity_properties_array', 'brush_entity_collision_shapes']

func get_context_key():
	return 'brush_entity_collision_shapes'

func should_spawn_collision_shapes(entity_definition_set: Dictionary, entity_properties: Dictionary) -> bool:
	if not 'classname' in entity_properties:
		return false

	var classname = entity_properties['classname']
	var entity_definition = entity_definition_set[classname]

	if entity_definition is QodotFGDSolidClass:
		return entity_definition.physics_body_type != QodotFGDSolidClass.PhysicsBodyType.NONE

	return false

func _finalize(context) -> Dictionary:
	if not 'brush_entity_collision_shapes' in context:
		return {}

	var brush_entity_collision_shapes = context['brush_entity_collision_shapes']
	var entity_definition_set = context['entity_definition_set']
	var entity_properties_array = context['entity_properties_array']

	var entity_collision_dict = {}

	for entity_idx in range(0, entity_properties_array.size()):
		var entity_properties = entity_properties_array[entity_idx]
		if not 'classname' in entity_properties:
			continue

		var classname = entity_properties['classname']
		var entity_definition = entity_definition_set[classname]

		if not entity_definition is QodotFGDSolidClass:
			continue

		if entity_definition.collision_shape_type == QodotFGDSolidClass.CollisionShapeType.NONE:
			continue

		var entity_center = Vector3.ZERO

		if entity_definition.spawn_type == QodotFGDSolidClass.SpawnType.ENTITY:
			# Calculate entity center
			for brush_idx in brush_entity_collision_shapes[get_entity_key(entity_idx)]:
				var area_collision_shape_data = brush_entity_collision_shapes[get_entity_key(entity_idx)][brush_idx]
				var brush_center = area_collision_shape_data['brush_center']
				entity_center += brush_center
			entity_center /= brush_entity_collision_shapes[get_entity_key(entity_idx)].size()

		var entity_key = null
		if entity_definition.spawn_type == QodotFGDSolidClass.SpawnType.ENTITY:
			entity_key = get_entity_key(entity_idx)
		else:
			entity_key = get_entity_key(0)

		# Build brush collision shapes
		if not entity_key in entity_collision_dict:
			entity_collision_dict[entity_key] = {
				'entity_physics_body': {}
			}

		if entity_definition.merge_brush_collision:
			var entity_collision_vertices = PoolVector3Array()
			for brush_idx in brush_entity_collision_shapes[entity_idx]:
				var area_collision_shape_data = brush_entity_collision_shapes[entity_idx][brush_idx]

				var brush_center = area_collision_shape_data['brush_center']
				var brush_collision_vertices = area_collision_shape_data['brush_collision_vertices']

				for vert_idx in range(0, brush_collision_vertices.size()):
					entity_collision_vertices.append(brush_collision_vertices[vert_idx] + (brush_center - entity_center))

			var entity_collision_shape = create_collision_shape(entity_definition, entity_collision_vertices)

			if entity_definition.spawn_type == QodotFGDSolidClass.SpawnType.ENTITY:
				entity_collision_shape.name = 'collision'
			else:
				entity_collision_shape.name = get_entity_key(entity_idx)

			entity_collision_dict[entity_key]['entity_physics_body'][get_entity_key(entity_idx)] = entity_collision_shape

		else:
			for brush_idx in brush_entity_collision_shapes[get_entity_key(entity_idx)]:
				var area_collision_shape_data = brush_entity_collision_shapes[get_entity_key(entity_idx)][brush_idx]

				var brush_center = area_collision_shape_data['brush_center']
				var brush_collision_vertices = area_collision_shape_data['brush_collision_vertices']

				var brush_collision_key = null
				if entity_definition.spawn_type == QodotFGDSolidClass.SpawnType.ENTITY:
					brush_collision_key = get_brush_key(brush_idx)
				else:
					brush_collision_key = get_entity_key(entity_idx) + "_" + get_brush_key(brush_idx)

				var brush_collision_shape = create_collision_shape(entity_definition, brush_collision_vertices)
				brush_collision_shape.name = brush_collision_key
				brush_collision_shape.translation = brush_center - entity_center

				entity_collision_dict[entity_key]['entity_physics_body'][brush_collision_key] = brush_collision_shape

	return {
		'nodes': {
			'brush_entities_node': entity_collision_dict
		}
	}

func create_collision_shape(entity_definition: QodotFGDSolidClass, entity_collision_vertices: PoolVector3Array) -> CollisionShape:
	match entity_definition.collision_shape_type:
		QodotFGDSolidClass.CollisionShapeType.CONVEX:
			return create_convex_collision_shape(entity_collision_vertices)
		QodotFGDSolidClass.CollisionShapeType.CONCAVE:
			return create_concave_collision_shape(entity_collision_vertices)

	return null
