class_name QodotBuildMaterialMeshes
extends QodotBuildMeshes

func get_name() -> String:
	return "material_meshes"

func get_type() -> int:
	return self.Type.SINGLE

func get_build_params() -> Array:
	return ['entity_properties_array', 'brush_data_dict', 'material_dict', 'inverse_scale_factor']

func get_finalize_params() -> Array:
	return ['material_meshes']

func get_wants_finalize():
	return true

var material_names = []
var material_index_paths = {}

func _run(context) -> Dictionary:
	# Fetch context variables
	var entity_properties_array = context['entity_properties_array']
	var brush_data_dict = context['brush_data_dict']
	var material_dict = context['material_dict']
	var inverse_scale_factor = context['inverse_scale_factor']

	foreach_entity_brush_face(
		entity_properties_array,
		brush_data_dict,
		funcref(self, 'boolean_true'),
		funcref(self, 'should_spawn_brush_mesh'),
		funcref(self, 'should_spawn_face_mesh'),
		funcref(self, 'get_material_name_and_index_path')
	)

	# Create one surface per material
	var material_surfaces = {}
	for material_name in material_names:
		var surface_tool = SurfaceTool.new()
		surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

		var face_index_paths = material_index_paths[material_name]
		for face_index_path in face_index_paths:
			var entity_idx = face_index_path[0]
			var brush_idx = face_index_path[1]
			var face_idx = face_index_path[2]
			var face_data = brush_data_dict[entity_idx][brush_idx]

			var brush = create_brush_from_face_data(face_data)
			var face = brush.faces[face_idx]

			var texture_size = Vector2.ZERO

			var material = material_dict[face.texture]
			if material:
				surface_tool.set_material(material)

				var albedo_texture = material.get_texture(SpatialMaterial.TEXTURE_ALBEDO)
				texture_size = albedo_texture.get_size() / inverse_scale_factor

			face.get_mesh(surface_tool, texture_size, Color.white, true)

		surface_tool.index()
		material_surfaces[material_name] = surface_tool

	# Return data for surface committing on the main thread
	return {
		'material_meshes': {
			'material_surfaces': material_surfaces
		}
	}

func get_material_name_and_index_path(entity_key, entity_properties, brush_key, brush, face_idx, face):
	if not face.texture in material_index_paths:
		material_index_paths[face.texture] = []

	if not face.texture in material_names:
		material_names.append(face.texture)

	material_index_paths[face.texture].append([entity_key, brush_key, face_idx])

func _finalize(context) -> Dictionary:
	# Fetch context data
	var material_meshes = context['material_meshes']

	# Fetch subdata
	var material_surfaces = material_meshes['material_surfaces']

	# Create single array mesh
	var array_mesh = ArrayMesh.new()

	# Commit material surfaces to array mesh
	for material_name in material_surfaces:
		var material_surface = material_surfaces[material_name]
		material_surface.commit(array_mesh)

	# Create MeshInstance, configure, and apply mesh
	var materials_node = MeshInstance.new()
	materials_node.name = "MaterialsMesh"
	materials_node.set_flag(MeshInstance.FLAG_USE_BAKED_LIGHT, true)
	materials_node.set_mesh(array_mesh)

	return {
		'meshes_to_unwrap': {
			'material_mesh': array_mesh
		},
		'nodes': {
			'mesh_node': {
				'materials_node': materials_node
			}
		}
	}
