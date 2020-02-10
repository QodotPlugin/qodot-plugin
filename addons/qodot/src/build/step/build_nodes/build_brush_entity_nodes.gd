class_name QodotBuildBrushEntityNodes
extends QodotBuildStep

func get_name() -> String:
	return "brush_entity_nodes"
func get_type() -> int:
	return self.Type.PER_ENTITY

func get_build_params() -> Array:
	return ['entity_definition_set', 'brush_data_dict']

func _run(context) -> Dictionary:
	var entity_idx = context['entity_idx']
	var entity_definition_set = context['entity_definition_set']
	var entity_properties = context['entity_properties']
	var brush_data_dict = context['brush_data_dict']

	var entity_center = Vector3.ZERO

	var brush_data = brush_data_dict[entity_idx]
	for brush_idx in brush_data:
		var face_data = brush_data[brush_idx]
		var brush = create_brush_from_face_data(face_data)
		entity_center += brush.center

	entity_center /= brush_data.size()

	var node = null

	if 'classname' in entity_properties:
		var classname = entity_properties['classname']
		var entity_definition = entity_definition_set[classname]

		if not entity_definition is QodotFGDSolidClass:
			return {}

		if entity_definition.spawn_type == QodotFGDSolidClass.SpawnType.MERGE_WORLDSPAWN:
			return {}

		if entity_definition.script_class:
			node = entity_definition.script_class.new()
		else:
			node = QodotEntity.new()

		node.name = 'entity_' + String(entity_idx) + '_' + classname
		if entity_definition.spawn_type == QodotFGDSolidClass.SpawnType.ENTITY:
			node.translation = entity_center
		node.set_meta("_edit_lock_", true)

		if 'properties' in node:
			node.properties = entity_properties

		return {
			'nodes': {
				'brush_entities_node': {
					get_entity_key(entity_idx): node
				}
			}
		}

	return {}
