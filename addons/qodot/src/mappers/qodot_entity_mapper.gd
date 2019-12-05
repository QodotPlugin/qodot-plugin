class_name QodotEntityMapper

static func spawn_entity(entity: QuakeEntity, inverse_scale_factor: float) -> QodotEntity:
	var entity_node = QodotEntity.new()

	if 'classname' in entity.properties:
		entity_node.name = entity.properties['classname']

	if 'origin' in entity.properties:
		entity_node.translation = entity.properties['origin'] / inverse_scale_factor

	if 'properties' in entity_node:
		entity_node.properties = entity.properties

	var entity_spawned_node = spawn_node_for_entity(entity)
	if(entity_spawned_node != null):
		entity_node.add_child(entity_spawned_node)
		if('angle' in entity.properties):
			entity_spawned_node.rotation.y = deg2rad(180 + entity.properties['angle'])

	return entity_node

static func spawn_node_for_entity(entity: QuakeEntity) -> Node:
	if('classname' in entity.properties):
		match entity.properties['classname']:
			'worldspawn':
				return null
			'trigger':
				return null

	return Position3D.new()
