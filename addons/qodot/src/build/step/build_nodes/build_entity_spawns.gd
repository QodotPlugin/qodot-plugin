class_name QodotBuildEntitySpawns
extends QodotBuildStep

class InstancedScene:
	var wrapped_node
	func _init(node : Node):
		wrapped_node = node

func get_name() -> String:
	return "entity_spawns"

func get_type() -> int:
	return self.Type.PER_ENTITY

func get_build_params() -> Array:
	return ['entity_definition_set']

func _run(context) -> Dictionary:
	var entity_idx = context['entity_idx']
	var entity_properties = context['entity_properties']

	var is_child_scene = false
	var node = null
	if('classname' in entity_properties):
		var classname = entity_properties['classname']
		if classname.substr(0, 5) == 'func_':
			node = null
		else:
			var entity_definition_set = context['entity_definition_set']
			if entity_definition_set.has(classname):
				var entity_def_data = entity_definition_set[classname]
				if entity_def_data is String:
					print("entity_def_data ", entity_def_data)
					var entity_def_scene = load(entity_def_data)
					node = entity_def_scene.instance(PackedScene.GEN_EDIT_STATE_INSTANCE)
					is_child_scene = true
				elif entity_def_data is Script:
					node = entity_def_data.new()
			else:
				node = QodotEntity.new()

			if 'properties' in node:
				node.properties = entity_properties

		if node:
			node.name = 'entity_' + String(entity_idx) + '_' + classname

	if not node:
		return {}

	if 'origin' in entity_properties:
		node.translation = entity_properties['origin']

	return {
		'nodes': {
			'entity_spawns_node': {
				get_entity_key(entity_idx): InstancedScene.new(node) if is_child_scene else node
			}
		}
	}
