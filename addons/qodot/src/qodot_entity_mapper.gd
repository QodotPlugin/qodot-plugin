class_name QodotEntityMapper

static func spawn_node_for_classname(classname: String) -> Node:
	match classname:
		'worldspawn':
			return null
		'trigger':
			return null
		_:
			return Position3D.new()
