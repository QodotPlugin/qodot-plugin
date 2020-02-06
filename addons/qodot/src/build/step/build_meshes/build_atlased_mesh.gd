class_name QodotBuildAtlasedMesh
extends QodotBuildMeshes

func get_name() -> String:
	return "atlased_mesh"

func get_type() -> int:
	return self.Type.SINGLE

func get_build_params() -> Array:
	return ['brush_data_dict', 'entity_properties_array', 'texture_atlas', 'texture_layered_mesh', 'inverse_scale_factor']

func get_wants_finalize() -> bool:
	return true

func get_finalize_params() -> Array:
	return ['build_atlased_mesh']

var surface_tool = null
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
	self.surface_tool = SurfaceTool.new()
	self.surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	foreach_entity_brush_face(
		entity_properties_array,
		brush_data_dict,
		funcref(self, 'boolean_true'),
		funcref(self, 'should_spawn_brush_mesh'),
		funcref(self, 'should_spawn_face_mesh'),
		funcref(self, 'get_face_mesh')
	)

	surface_tool.index()

	var array_mesh = ArrayMesh.new()
	texture_layered_mesh.set_meshes([array_mesh])

	return {
		'build_atlased_mesh': {
			'atlased_mesh': array_mesh,
			'atlased_surface': self.surface_tool,
			'texture_layered_mesh': texture_layered_mesh
		}
	}

func get_face_mesh(entity_key, entity_properties: Dictionary, brush_key, brush: QuakeBrush, face_idx, face: QuakeFace):
	var texture_idx = atlas_texture_names.find(face.texture)

	var atlas_size = atlas_sizes[texture_idx] / inverse_scale_factor
	var texture_vertex_color = Color()
	texture_vertex_color.r = float(texture_idx) / float(atlas_texture_names.size() - 1)
	face.get_mesh(self.surface_tool, atlas_size, texture_vertex_color, true, should_smooth_face_normals(entity_properties))

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
