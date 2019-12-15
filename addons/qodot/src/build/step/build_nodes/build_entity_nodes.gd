class_name QodotBuildEntityNodes
extends QodotBuildStep

func get_name() -> String:
	return "entity_nodes"

func get_type() -> int:
	return self.Type.PER_ENTITY

func get_build_params() -> Array:
	return ['inverse_scale_factor']

func _run(context) -> Dictionary:
	var entity_idx = context['entity_idx']
	var entity_properties = context['entity_properties']
	var inverse_scale_factor = context['inverse_scale_factor']

	var entity_node = QodotEntity.new()
	entity_node.properties = entity_properties

	if 'classname' in entity_properties:
		entity_node.name = 'Entity' + String(entity_idx)

	if 'origin' in entity_properties:
		entity_node.translation = entity_properties['origin'] / inverse_scale_factor

	return {
		'nodes': {
			'entity_' + String(entity_idx): entity_node
		}
	}
