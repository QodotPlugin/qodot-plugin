class_name QodotBuildBrushFaceMeshes
extends QodotBuildMeshes

func get_name() -> String:
	return "brush_face_meshes"

func get_type() -> int:
	return self.Type.PER_BRUSH

func get_build_params() -> Array:
	return ['material_dict', 'inverse_scale_factor']

func get_finalize_params() -> Array:
	return ['brush_face_meshes', 'material_dict', 'inverse_scale_factor']

func get_wants_finalize():
	return true

func _run(context) -> Array:
	var entity_idx = context['entity_idx']
	var brush_idx = context['brush_idx']
	var entity_properties = context['entity_properties']
	var brush_data = context['brush_data']
	var material_dict = context['material_dict']
	var inverse_scale_factor = context['inverse_scale_factor']

	var map_reader = QuakeMapReader.new()
	var brush = map_reader.create_brush(brush_data)

	if not should_spawn_brush_mesh(entity_properties, brush):
		return ["nodes", [entity_idx, brush_idx], [], [], []]

	var face_nodes = []
	var face_indices = []

	for face_idx in range(0, brush.faces.size()):
		var face = brush.faces[face_idx]
		if(should_spawn_face_mesh(entity_properties, brush, face)):
			var face_mesh_node = MeshInstance.new()
			face_mesh_node.name = 'Face0'
			face_nodes.append(face_mesh_node)
			face_indices.append(face_idx)

	return ["nodes", [entity_idx, brush_idx], face_nodes, face_indices, brush_data]

func _finalize(context):
	var brush_face_meshes = context['brush_face_meshes']
	var material_dict = context['material_dict']
	var inverse_scale_factor = context['inverse_scale_factor']

	for brush_face_mesh in brush_face_meshes:
		var face_nodes = brush_face_mesh[2]
		var face_indices = brush_face_mesh[3]
		var brush_data = brush_face_mesh[4]

		var map_reader = QuakeMapReader.new()
		var brush = map_reader.create_brush(brush_data)

		for face_idx in range(0, face_nodes.size()):
			var face_node = face_nodes[face_idx]
			var brush_face_idx = face_indices[face_idx]
			if(face_node):
				var face = brush.faces[brush_face_idx]
				var surface_tool = SurfaceTool.new()
				surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
				get_face_mesh(surface_tool, brush.center, face, material_dict, inverse_scale_factor, false)
				face_node.translation = (face.center - brush.center) / inverse_scale_factor
				face_node.set_mesh(surface_tool.commit())
