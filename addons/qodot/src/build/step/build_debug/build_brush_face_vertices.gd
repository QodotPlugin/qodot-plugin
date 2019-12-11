class_name QodotBuildBrushFaceVertices
extends QodotBuildStep

func get_name() -> String:
	return "brush_face_vertices"

func get_type() -> int:
	return self.Type.PER_BRUSH

func get_build_params() -> Array:
	return ['material_dict', 'inverse_scale_factor']

func _run(context) -> Array:
	var entity_idx = context['entity_idx']
	var brush_idx = context['brush_idx']
	var entity_properties = context['entity_properties']
	var brush_data = context['brush_data']
	var material_dict = context['material_dict']
	var inverse_scale_factor = context['inverse_scale_factor']

	var map_reader = QuakeMapReader.new()
	var brush = map_reader.create_brush(brush_data)

	var face_vertices = []

	for face in brush.faces:
		var vertices = face.face_vertices
		var face_spatial = QodotSpatial.new()
		face_spatial.name = 'Face0'
		face_spatial.translation = (face.center - brush.center) / inverse_scale_factor
		face_vertices.append(face_spatial)

		for vertex in vertices:
			var vertex_node = Position3D.new()
			vertex_node.name = 'Point0'
			vertex_node.translation = vertex / inverse_scale_factor
			face_spatial.add_child(vertex_node)

	return ["nodes", get_brush_attach_path(entity_idx, brush_idx), face_vertices]
