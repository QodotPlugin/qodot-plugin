class_name QodotBuildBrushNodes
extends QodotBuildStep

func get_name() -> String:
	return "brush_nodes"

func get_type() -> int:
	return self.Type.PER_BRUSH

func _run(context) -> Dictionary:
	var entity_idx = context['entity_idx']
	var brush_idx = context['brush_idx']
	var brush_data = context['brush_data']

	var brush = create_brush_from_face_data(brush_data)

	var brush_node = QodotBrush.new()
	brush_node.name = 'Brush' + String(brush_idx)
	brush_node.translation = brush.center

	return {
		'nodes': {
			get_entity_key(entity_idx): {
				get_brush_key(brush_idx): brush_node
			}
		}
	}
