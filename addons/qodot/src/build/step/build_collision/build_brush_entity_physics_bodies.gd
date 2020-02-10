class_name QodotBuildBrushEntityPhysicsBodies
extends QodotBuildStep

func get_name() -> String:
	return 'brush_entity_physics_bodies'

func get_finalize_params() -> Array:
	return ['entity_definition_set', 'entity_properties_array']

func get_wants_finalize():
	return true

func _finalize(context) -> Dictionary:
	var entity_definition_set = context['entity_definition_set']
	var entity_properties_array = context['entity_properties_array']

	var area_collision_dict = {}

	for entity_idx in range(0, entity_properties_array.size()):
		var entity_properties = entity_properties_array[entity_idx]

		if not 'classname' in entity_properties:
			continue

		var classname = entity_properties['classname']
		var entity_definition = entity_definition_set[classname]

		if not entity_definition is QodotFGDSolidClass:
			continue

		if entity_definition.physics_body_type == QodotFGDSolidClass.PhysicsBodyType.NONE:
			continue

		if entity_definition.spawn_type == QodotFGDSolidClass.SpawnType.MERGE_WORLDSPAWN:
			continue

		var entity_collision = null
		match(entity_definition.physics_body_type):
			QodotFGDSolidClass.PhysicsBodyType.AREA:
				entity_collision = Area.new()
			QodotFGDSolidClass.PhysicsBodyType.STATIC_BODY:
				entity_collision = StaticBody.new()
			QodotFGDSolidClass.PhysicsBodyType.KINEMATIC_BODY:
				entity_collision = KinematicBody.new()
			QodotFGDSolidClass.PhysicsBodyType.RIGID_BODY:
				entity_collision = RigidBody.new()

		entity_collision.name = 'collision'

		area_collision_dict[get_entity_key(entity_idx)] = {
			'entity_physics_body': entity_collision
		}

	return {
		'nodes': {
			'brush_entities_node': area_collision_dict
		}
	}
