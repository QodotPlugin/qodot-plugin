class_name QodotEntityMapper

static func spawn_node_for_entity(entity: QuakeEntity) -> Node:
	if('classname' in entity.properties):
		match entity.properties['classname']:
			'worldspawn':
				return null
			'trigger':
				return null

	return Position3D.new()
