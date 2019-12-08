class_name QodotBuildMaterialMeshes
extends QodotBuildMeshes

func get_name() -> String:
	return "material_meshes"

func get_type() -> int:
	return self.Type.SINGLE

func get_build_params() -> Array:
	return ['material_dict', 'entity_properties_array', 'brush_data_dict']

func get_finalize_params() -> Array:
	return ['material_meshes', 'brush_data_dict', 'material_dict', 'inverse_scale_factor']

func get_wants_finalize():
	return true

func _run(context) -> Array:
	var brush_data_dict = context['brush_data_dict']
	var material_dict = context['material_dict']
	var entity_properties_array = context['entity_properties_array']

	var material_names = []

	var material_index_paths = {}
	for entity_key in brush_data_dict:
		var entity_brushes = brush_data_dict[entity_key]
		var entity_properties = entity_properties_array[entity_key]

		for brush_key in entity_brushes:
			var face_data = entity_brushes[brush_key]
			var map_reader = QuakeMapReader.new()
			var brush = map_reader.create_brush(face_data)

			if not should_spawn_brush_mesh(entity_properties, brush):
				continue

			for face_idx in range(0, brush.faces.size()):
				var face = brush.faces[face_idx]
				if not should_spawn_face_mesh(entity_properties, brush, face):
					continue

				if not face.texture in material_index_paths:
					material_index_paths[face.texture] = []

				if not face.texture in material_names:
					material_names.append(face.texture)

				material_index_paths[face.texture].append([entity_key, brush_key, face_idx])

	var material_nodes = []
	for material_name in material_names:
		var material_node = MeshInstance.new()
		material_node.name = material_name
		material_nodes.append(material_node)

	return ["nodes", [], material_nodes, material_index_paths, material_names]

func _finalize(context):
	var material_meshes = context['material_meshes']
	var brush_data_dict = context['brush_data_dict']
	var material_dict = context['material_dict']
	var inverse_scale_factor = context['inverse_scale_factor']

	var material_nodes = material_meshes[0][2]
	var material_index_paths = material_meshes[0][3]
	var material_names = material_meshes[0][4]

	for texture_name_idx in range(0, material_names.size()):
		var material_name = material_names[texture_name_idx]
		var material_node = material_nodes[texture_name_idx]

		var surface_tool = SurfaceTool.new()
		surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

		var face_index_paths = material_index_paths[material_name]
		for face_index_path in face_index_paths:
			var entity_idx = face_index_path[0]
			var brush_idx = face_index_path[1]
			var face_idx = face_index_path[2]
			var face_data = brush_data_dict[entity_idx][brush_idx]

			var map_reader = QuakeMapReader.new()
			var brush = map_reader.create_brush(face_data)
			var face = brush.faces[face_idx]

			get_face_mesh(surface_tool, brush.center, face, material_dict, inverse_scale_factor, true)

		surface_tool.index()
		material_node.set_mesh(surface_tool.commit())
