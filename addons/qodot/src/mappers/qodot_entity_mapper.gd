class_name QodotEntityMapper

static func spawn_entity(properties: Dictionary, inverse_scale_factor: float) -> QodotEntity:
	var entity_node = QodotEntity.new()
	entity_node.properties = properties

	if 'classname' in entity_node.properties:
		entity_node.name = entity_node.properties['classname']

	if 'origin' in entity_node.properties:
		entity_node.translation = entity_node.properties['origin'] / inverse_scale_factor

	return entity_node

static func spawn_node_for_entity(properties: Dictionary) -> Node:
	var node = null

	if('classname' in properties):
		var classname = properties['classname']
		if classname.substr(0, 5) != 'func_' and classname != 'worldspawn' and classname != 'trigger' and classname != 'func_group':
			node = Position3D.new()

	if node:
		if 'angle' in properties:
			node.rotation.y = deg2rad(180 + properties['angle'])

	return node
