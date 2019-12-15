class_name QodotBuildEntityNodes
extends QodotBuildStep

func get_name() -> String:
	return "entity_nodes"

func get_type() -> int:
	return self.Type.PER_ENTITY

func _run(context) -> Dictionary:
	var entity_idx = context['entity_idx']
	var entity_properties = context['entity_properties']

	var entity_node = QodotEntity.new()
	entity_node.properties = entity_properties

	if 'classname' in entity_properties:
		entity_node.name = 'Entity' + String(entity_idx)

	if 'origin' in entity_properties:
		entity_node.translation = entity_properties['origin']

	return {
		'nodes': {
			get_entity_key(entity_idx): entity_node
		}
	}
