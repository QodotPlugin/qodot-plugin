class_name QodotBuildPointEntities
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
		if classname == 'worldspawn':
			node = null
		else:
			var entity_definition_set = context['entity_definition_set']
			if entity_definition_set.has(classname):
				var entity_def_data = entity_definition_set[classname]

				if entity_def_data is QodotFGDPointClass:
					if entity_def_data.scene_file:
						var entity_def_scene = load(entity_def_data.scene_file)
						node = entity_def_scene.instance(PackedScene.GEN_EDIT_STATE_INSTANCE)
						is_child_scene = true
					elif entity_def_data.script_class:
						node = entity_def_data.script_class.new()
				elif entity_def_data is QodotFGDSolidClass:
					if entity_def_data.script_class:
						node = entity_def_data.script_class.new()
			else:
				node = QodotEntity.new()

		if node:
			node.name = 'entity_' + String(entity_idx) + '_' + classname\

			if 'properties' in node:
				node.properties = entity_properties

	if not node:
		return {}

	if 'origin' in entity_properties:
		node.translation = entity_properties['origin']

	return {
		'nodes': {
			'point_entities_node': {
				get_entity_key(entity_idx): InstancedScene.new(node) if is_child_scene else node
			}
		}
	}
