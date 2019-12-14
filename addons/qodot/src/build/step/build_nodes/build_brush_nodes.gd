class_name QodotBuildBrushNodes
extends QodotBuildStep

func get_name() -> String:
	return "brush_nodes"

func get_type() -> int:
	return self.Type.PER_BRUSH

func get_build_params() -> Array:
	return ['inverse_scale_factor']

func _run(context) -> Dictionary:
	var entity_idx = context['entity_idx']
	var brush_idx = context['brush_idx']
	var brush_data = context['brush_data']
	var inverse_scale_factor = context['inverse_scale_factor']

	var map_reader = QuakeMapReader.new()
	var brush = map_reader.create_brush(brush_data)

	var brush_node = QodotBrush.new()
	brush_node.name = 'Brush' + String(brush_idx)
	brush_node.translation = brush.center / inverse_scale_factor

	return {
		'nodes': {
			'entity_' + entity_idx: {
				'brush_' + brush_idx: brush_node
			}
		}
	}
