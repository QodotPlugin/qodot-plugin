class_name QodotBuildEntitySpawns
extends QodotBuildStep

func get_name() -> String:
	return "entity_spawns"

func get_type() -> int:
	return self.Type.PER_ENTITY

func get_build_params() -> Array:
	return ['inverse_scale_factor']

func _run(context) -> Array:
	var entity_idx = context['entity_idx']
	var entity_properties = context['entity_properties']

	var node = null

	if('classname' in entity_properties):
		var classname = entity_properties['classname']
		if classname.substr(0, 5) != 'func_' and classname != 'worldspawn' and classname != 'trigger' and classname != 'func_group':
			node = Position3D.new()

	var spawned_nodes = []
	if node:
		if 'angle' in entity_properties:
			node.rotation.y = deg2rad(180 + entity_properties['angle'])
		spawned_nodes.append(node)

	return ["nodes", [entity_idx], [spawned_nodes]]
