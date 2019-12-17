class_name QodotBuildAtlasedMesh
extends QodotBuildMeshes

var atlas_material := preload("res://textures/shaders/atlas.tres") as ShaderMaterial

func get_name() -> String:
	return "atlased_mesh"

func get_type() -> int:
	return self.Type.SINGLE

func get_build_params() -> Array:
	return ['brush_data_dict', 'entity_properties_array', 'texture_atlas', 'inverse_scale_factor']

func get_wants_finalize() -> bool:
	return true

func get_finalize_params() -> Array:
	return ['build_atlased_mesh']

func _run(context) -> Dictionary:
	# Fetch context data
	var brush_data_dict = context['brush_data_dict']
	var entity_properties_array = context['entity_properties_array']
	var texture_atlas = context['texture_atlas']
	var inverse_scale_factor = context['inverse_scale_factor']

	# Fetch subdata
	var atlas_texture_names = texture_atlas['atlas_texture_names']
	var atlas_sizes = texture_atlas['atlas_sizes']
	var atlas_textures = texture_atlas['atlas_textures']
	var atlas_data_texture = texture_atlas['atlas_data_texture']

	# Build brush geometry
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	for entity_key in brush_data_dict:
		var entity_brushes = brush_data_dict[entity_key]
		var entity_properties = entity_properties_array[entity_key]

		for brush_key in entity_brushes:
			var face_data = entity_brushes[brush_key]
			var brush = create_brush_from_face_data(face_data)

			if not should_spawn_brush_mesh(entity_properties, brush):
				continue

			for face_idx in range(0, brush.faces.size()):
				var face = brush.faces[face_idx]

				if not should_spawn_face_mesh(entity_properties, brush, face):
					continue

				var texture_idx = atlas_texture_names.find(face.texture)

				var atlas_size = atlas_sizes[texture_idx] / inverse_scale_factor
				var texture_vertex_color = Color()
				texture_vertex_color.r = float(texture_idx) / float(atlas_texture_names.size() - 1)
				face.get_mesh(surface_tool, atlas_size, texture_vertex_color, true)

	surface_tool.index()

	# Create TextureLayeredMesh
	var texture_layered_mesh = QodotTextureLayeredMesh.new()
	texture_layered_mesh.name = 'Mesh'
	texture_layered_mesh.set_shader_parameter('atlas_array')
	texture_layered_mesh.set_texture_format(QodotTextureLayeredMesh.TextureFormat.RGB8)

	# Configure atlas material
	var material = atlas_material.duplicate()
	material.set_shader_param('atlas_data', atlas_data_texture)

	# Assign generated data to TextureLayeredMesh
	texture_layered_mesh.set_shader_material(material)
	texture_layered_mesh.set_array_data(atlas_textures)

	var array_mesh = ArrayMesh.new()
	texture_layered_mesh.set_mesh(array_mesh)

	return {
		'build_atlased_mesh': {
			'texture_layered_mesh': texture_layered_mesh,
			'atlased_mesh': array_mesh,
			'atlased_surface': surface_tool
		},
		'nodes': {
			'texture_layered_mesh': texture_layered_mesh
		}
	}

func _finalize(context: Dictionary) -> Dictionary:
	var build_atlased_mesh = context['build_atlased_mesh']

	var texture_layered_mesh = build_atlased_mesh['texture_layered_mesh']
	var atlased_mesh = build_atlased_mesh['atlased_mesh']
	var atlased_surface = build_atlased_mesh['atlased_surface']

	atlased_surface.commit(atlased_mesh)

	texture_layered_mesh.call_deferred('set_reload', true)

	return {
		'meshes_to_unwrap': {
			'atlased_mesh': atlased_mesh
		}
	}
