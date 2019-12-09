class_name QodotBuildBrushFaceAxes
extends QodotBuildStep

func get_name() -> String:
	return "brush_face_axes"

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

	var face_axes = []

	for face in brush.faces:
		var face_axes_node = QuakePlaneAxes.new()
		face_axes_node.name = 'Plane0'
		face_axes_node.translation = (face.plane_vertices[0] - brush.center) / inverse_scale_factor

		face_axes_node.vertex_set = []
		for vertex in face.plane_vertices:
			face_axes_node.vertex_set.append(((vertex - face.plane_vertices[0]) / inverse_scale_factor))

		face_axes.append(face_axes_node)

	return ["nodes", get_brush_attach_path(entity_idx, brush_idx), face_axes]
