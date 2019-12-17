class_name QodotBuildAtlasedMeshPerBrush
extends QodotBuildMeshes

func get_name() -> String:
	return "atlased_mesh_per_brush"

func get_type() -> int:
	return self.Type.SINGLE

func get_build_params() -> Array:
	return ['brush_data_dict', 'entity_properties_array', 'texture_atlas', 'texture_layered_mesh', 'inverse_scale_factor']

func get_wants_finalize() -> bool:
	return true

func get_finalize_params() -> Array:
	return ['build_atlased_mesh']

var brush_surface_tools = {}
var atlas_texture_names = null
var atlas_sizes = null
var inverse_scale_factor = null

func _run(context) -> Dictionary:
	# Fetch context data
	var brush_data_dict = context['brush_data_dict']
	var entity_properties_array = context['entity_properties_array']
	var texture_atlas = context['texture_atlas']
	var texture_layered_mesh = context['texture_layered_mesh']
	self.inverse_scale_factor = context['inverse_scale_factor']

	# Fetch subdata
	self.atlas_texture_names = texture_atlas['atlas_texture_names']
	self.atlas_sizes = texture_atlas['atlas_sizes']

	# Build brush geometry
	var array_meshes = {}
	for entity_idx in brush_data_dict:
		var entity_properties = entity_properties_array[entity_idx]
		var entity_brush_data = brush_data_dict[entity_idx]
		brush_surface_tools[entity_idx] = {}
		array_meshes[entity_idx] = {}

		for brush_idx in entity_brush_data:
			var brush = create_brush_from_face_data(entity_brush_data[brush_idx])

			if not should_spawn_brush_mesh(entity_properties, brush):
				continue

			var surface_tool = SurfaceTool.new()
			surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
			brush_surface_tools[entity_idx][brush_idx] = surface_tool

			var results = foreach_face(
				entity_idx,
				entity_properties,
				brush_idx,
				brush,
				funcref(self, 'should_spawn_face_mesh'),
				funcref(self, 'get_face_mesh')
			)

			if results.size() > 0:
				surface_tool.index()
				array_meshes[entity_idx][brush_idx] = ArrayMesh.new()
			else:
				brush_surface_tools[entity_idx].erase(brush_idx)

	var array_mesh_array = []
	for entity_idx in array_meshes:
		for brush_idx in array_meshes[entity_idx]:
			var array_mesh = array_meshes[entity_idx][brush_idx]
			array_mesh_array.append(array_mesh)
	texture_layered_mesh.set_meshes(array_mesh_array)

	return {
		'build_atlased_mesh': {
			'atlased_meshes': array_meshes,
			'atlased_surfaces': brush_surface_tools,
			'texture_layered_mesh': texture_layered_mesh
		}
	}

func get_face_mesh(entity_key, entity_properties: Dictionary, brush_key, brush: QuakeBrush, face_idx, face: QuakeFace):
	var texture_idx = atlas_texture_names.find(face.texture)

	var atlas_size = atlas_sizes[texture_idx] / inverse_scale_factor
	var texture_vertex_color = Color()
	texture_vertex_color.r = float(texture_idx) / float(atlas_texture_names.size() - 1)

	face.get_mesh(brush_surface_tools[entity_key][brush_key], atlas_size, texture_vertex_color, true)

	return true

func _finalize(context: Dictionary) -> Dictionary:
	var build_atlased_mesh = context['build_atlased_mesh']

	var texture_layered_mesh = build_atlased_mesh['texture_layered_mesh']
	var atlased_meshes = build_atlased_mesh['atlased_meshes']
	var atlased_surfaces = build_atlased_mesh['atlased_surfaces']

	var meshes_to_unwrap = {}
	for entity_idx in atlased_meshes:
		var entity_meshes = atlased_meshes[entity_idx]
		var entity_surfaces = atlased_surfaces[entity_idx]

		for brush_idx in entity_meshes:
			var atlased_mesh = entity_meshes[brush_idx]
			var atlased_surface = entity_surfaces[brush_idx]
			atlased_surface.commit(atlased_mesh)
			meshes_to_unwrap[get_entity_brush_key(entity_idx, brush_idx)] = atlased_mesh

	texture_layered_mesh.call_deferred('set_reload', true)

	return {
		'meshes_to_unwrap': meshes_to_unwrap
	}
