class_name QodotBuildBrushFaceVertices
extends QodotBuildStep

func get_name() -> String:
	return "brush_face_vertices"

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

	var face_vertex_dict = {}

	for face_idx in range(0, brush.faces.size()):
		var face_key = get_face_key(face_idx)

		var face = brush.faces[face_idx]
		var vertices = face.face_vertices
		var face_spatial = QodotSpatial.new()
		face_spatial.name = face_key + '_Vertices'
		face_spatial.translation = (face.center - brush.center)
		face_vertex_dict[face_key] = face_spatial

		for vertex in vertices:
			var vertex_node = Position3D.new()
			vertex_node.name = 'Point0'
			vertex_node.translation = vertex
			face_spatial.add_child(vertex_node)

	return {
		'nodes': {
			get_entity_key(entity_idx): {
				get_brush_key(brush_idx): face_vertex_dict
			}
		}
	}
