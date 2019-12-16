class_name QodotBuildBrushFaceMeshes
extends QodotBuildMeshes

func get_name() -> String:
	return "brush_face_meshes"

func get_type() -> int:
	return self.Type.PER_BRUSH

func get_build_params() -> Array:
	return ['material_dict', 'inverse_scale_factor']

func get_finalize_params() -> Array:
	return ['brush_face_meshes']

func get_wants_finalize():
	return true

func _run(context) -> Dictionary:
	var entity_idx = context['entity_idx']
	var brush_idx = context['brush_idx']
	var entity_properties = context['entity_properties']
	var brush_data = context['brush_data']
	var material_dict = context['material_dict']
	var inverse_scale_factor = context['inverse_scale_factor']

	var brush = create_brush_from_face_data(brush_data)

	if not should_spawn_brush_mesh(entity_properties, brush):
		return {}

	var face_nodes = {}
	var face_surfaces = {}

	var brush_key = get_entity_brush_key(entity_idx, brush_idx)

	for face_idx in range(0, brush.faces.size()):
		var face = brush.faces[face_idx]

		if(should_spawn_face_mesh(entity_properties, brush, face)):
			var face_key = brush_key + get_face_key(face_idx)
			var face_mesh_node = MeshInstance.new()
			face_mesh_node.name = 'Face0'
			face_mesh_node.translation = (face.center - brush.center)
			face_nodes[face_key] = face_mesh_node

			var surface_tool = SurfaceTool.new()

			surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

			var texture_size = Vector2.ZERO

			var material = material_dict[face.texture]
			if material:
				surface_tool.set_material(material)
				texture_size = material.get_texture(SpatialMaterial.TEXTURE_ALBEDO).get_size() / inverse_scale_factor

			face.get_mesh(surface_tool, texture_size, Color.white, false)

			face_surfaces[face_key] = surface_tool

	return {
		'brush_face_meshes': {
			brush_key: {
				'face_nodes': face_nodes,
				'face_surfaces': face_surfaces
			}
		},
		'nodes': {
			get_entity_key(entity_idx): {
				get_brush_key(brush_idx): face_nodes
			}
		}
	}

func _finalize(context) -> Dictionary:
	var brush_face_meshes = context['brush_face_meshes']

	for brush_face_key in brush_face_meshes:
		var brush_face_mesh = brush_face_meshes[brush_face_key]
		var face_nodes = brush_face_mesh['face_nodes']
		var face_surfaces = brush_face_mesh['face_surfaces']

		for face_node_key in face_nodes:
			var face_node = face_nodes[face_node_key]
			var face_surface = face_surfaces[face_node_key]
			face_node.set_mesh(face_surface.commit())

	return {}
