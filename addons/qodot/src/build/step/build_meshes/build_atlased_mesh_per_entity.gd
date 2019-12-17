class_name QodotBuildAtlasedMeshPerEntity
extends QodotBuildMeshes

func get_name() -> String:
	return "atlased_mesh_per_entity"

func get_type() -> int:
	return self.Type.SINGLE

func get_build_params() -> Array:
	return ['brush_data_dict', 'entity_properties_array', 'texture_atlas', 'texture_layered_mesh', 'inverse_scale_factor']

func get_wants_finalize() -> bool:
	return true

func get_finalize_params() -> Array:
	return ['build_atlased_mesh']

var entity_surface_tools = {}
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
		var brush_data = brush_data_dict[entity_idx]

		var surface_tool = SurfaceTool.new()
		surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		entity_surface_tools[entity_idx] = surface_tool

		var results = foreach_brush_face(
			entity_idx,
			entity_properties_array[entity_idx],
			brush_data_dict[entity_idx],
			funcref(self, 'should_spawn_brush_mesh'),
			funcref(self, 'should_spawn_face_mesh'),
			funcref(self, 'get_face_mesh')
		)

		if results.size() > 0:
			surface_tool.index()
			array_meshes[entity_idx] = ArrayMesh.new()
		else:
			entity_surface_tools.erase(entity_idx)

	texture_layered_mesh.set_meshes(array_meshes.values())

	return {
		'build_atlased_mesh': {
			'atlased_meshes': array_meshes,
			'atlased_surfaces': entity_surface_tools,
			'texture_layered_mesh': texture_layered_mesh
		}
	}

func get_face_mesh(entity_key, entity_properties: Dictionary, brush_key, brush: QuakeBrush, face_idx, face: QuakeFace):
	var texture_idx = atlas_texture_names.find(face.texture)

	var atlas_size = atlas_sizes[texture_idx] / inverse_scale_factor
	var texture_vertex_color = Color()
	texture_vertex_color.r = float(texture_idx) / float(atlas_texture_names.size() - 1)
	face.get_mesh(entity_surface_tools[entity_key], atlas_size, texture_vertex_color, true)

	return true

func _finalize(context: Dictionary) -> Dictionary:
	var build_atlased_mesh = context['build_atlased_mesh']

	var texture_layered_mesh = build_atlased_mesh['texture_layered_mesh']
	var atlased_meshes = build_atlased_mesh['atlased_meshes']
	var atlased_surfaces = build_atlased_mesh['atlased_surfaces']

	var meshes_to_unwrap = {}
	for entity_idx in atlased_meshes:
		var atlased_mesh = atlased_meshes[entity_idx]
		var atlased_surface = atlased_surfaces[entity_idx]
		atlased_surface.commit(atlased_mesh)
		meshes_to_unwrap[entity_idx] = atlased_mesh

	texture_layered_mesh.call_deferred('set_reload', true)

	return {
		'meshes_to_unwrap': meshes_to_unwrap
	}
