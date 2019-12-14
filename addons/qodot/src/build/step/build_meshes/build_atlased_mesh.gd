class_name QodotBuildAtlasedMesh
extends QodotBuildMeshes

var atlas_material := preload("res://textures/shaders/atlas.tres") as ShaderMaterial

func get_name() -> String:
	return "atlased_mesh"

func get_type() -> int:
	return self.Type.SINGLE

func get_build_params() -> Array:
	return ['entity_properties_array', 'brush_data_dict']

func get_finalize_params() -> Array:
	return ['atlased_mesh', 'brush_data_dict', 'texture_atlas', 'inverse_scale_factor']

func get_wants_finalize():
	return true

func _run(context) -> Array:
	var brush_data_dict = context['brush_data_dict']
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

	var texture_layered_mesh = QodotTextureLayeredMesh.new()
	texture_layered_mesh.name = 'TextureLayeredMesh'
	texture_layered_mesh.set_shader_parameter('atlas_array')
	texture_layered_mesh.set_texture_format(QodotTextureLayeredMesh.TextureFormat.RGB8)

	return ["nodes", "./Meshes", [texture_layered_mesh], material_index_paths, material_names]

func _finalize(context):
	var atlased_mesh = context['atlased_mesh']
	var brush_data_dict = context['brush_data_dict']
	var texture_atlas = context['texture_atlas'][0]
	var inverse_scale_factor = context['inverse_scale_factor']

	var atlas_texture_names = texture_atlas[1]
	var atlas_positions = texture_atlas[2]
	var atlas_sizes = texture_atlas[3]
	var atlas_textures = texture_atlas[4]
	var atlas_data_texture = texture_atlas[5]

	var texture_layered_mesh := atlased_mesh[0][2][0] as QodotTextureLayeredMesh
	var material_index_paths = atlased_mesh[0][3]
	var material_names = atlased_mesh[0][4]

	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	for texture_name in atlas_texture_names:
		var texture_idx = atlas_texture_names.find(texture_name)
		var atlas_size = atlas_sizes[texture_idx]

		var texture_vertex_color = Color()
		texture_vertex_color.r = float(texture_idx) / float(atlas_texture_names.size() - 1)

		if texture_name in material_index_paths:
			var face_index_paths = material_index_paths[texture_name]
			for face_index_path in face_index_paths:
				var entity_idx = face_index_path[0]
				var brush_idx = face_index_path[1]
				var face_idx = face_index_path[2]
				var face_data = brush_data_dict[entity_idx][brush_idx]

				var map_reader = QuakeMapReader.new()
				var brush = map_reader.create_brush(face_data)
				var face = brush.faces[face_idx]

				get_face_mesh(surface_tool, brush.center, face, atlas_size, texture_vertex_color, inverse_scale_factor, true)

	texture_layered_mesh.set_mesh(surface_tool.commit())

	var material = atlas_material.duplicate()
	material.set_shader_param('atlas_data', atlas_data_texture)
	texture_layered_mesh.set_shader_material(material)
	texture_layered_mesh.set_array_data(atlas_textures)
