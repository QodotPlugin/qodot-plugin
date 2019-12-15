class_name QodotBuildBrushFaceAxes
extends QodotBuildStep

func get_name() -> String:
	return "brush_face_axes"

func get_type() -> int:
	return self.Type.PER_BRUSH

func get_build_params() -> Array:
	return ['material_dict']

func _run(context) -> Dictionary:
	var entity_idx = context['entity_idx']
	var brush_idx = context['brush_idx']
	var entity_properties = context['entity_properties']
	var brush_data = context['brush_data']
	var material_dict = context['material_dict']

	var brush = create_brush_from_face_data(brush_data)

	var face_axes_dict = {}

	for face_idx in range(0, brush.faces.size()):
		var face_key = get_face_key(face_idx)

		var face = brush.faces[face_idx]
		var face_axes_node = QuakePlaneAxes.new()
		face_axes_node.name = face_key + '_Plane'
		face_axes_node.translation = (face.plane_vertices[0] - brush.center)

		face_axes_node.vertex_set = []
		for vertex in face.plane_vertices:
			face_axes_node.vertex_set.append(((vertex - face.plane_vertices[0])))

		face_axes_dict[face_key] = face_axes_node

	return {
		'nodes': {
			get_entity_key(entity_idx): {
				get_brush_key(brush_idx): face_axes_dict
			}
		}
	}
