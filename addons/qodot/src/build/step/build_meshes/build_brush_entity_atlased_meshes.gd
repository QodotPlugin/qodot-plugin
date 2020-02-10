class_name QodotBuildBrushEntityAtlasedMeshes
extends QodotBuildMeshes

func get_name() -> String:
	return "brush_entity_atlased_meshes"

func get_type() -> int:
	return self.Type.SINGLE

func get_build_params() -> Array:
	return ['brush_data_dict', 'entity_definition_set', 'entity_properties_array', 'texture_atlas', 'inverse_scale_factor']

func get_wants_finalize() -> bool:
	return true

func get_finalize_params() -> Array:
	return ['brush_entity_atlased_meshes']

# Determine whether the given brush should create a set of visual face meshes
func should_spawn_brush_mesh(entity_definitions: Dictionary, entity_properties: Dictionary, brush: QuakeBrush) -> bool:
	if(brush.is_clip_brush()):
		return false

	if not 'classname' in entity_properties:
		return true

	var classname = entity_properties['classname']
	if classname in entity_definitions.keys():
		var entity_definition = entity_definitions[classname]

		if not entity_definition is QodotFGDSolidClass:
			return false

		return entity_definition.visual_build_type == QodotFGDSolidClass.VisualBuildType.ATLASED_MESHES

	# Should never reach here
	return false

var entity_surface_tools = {}
var atlas_texture_names = null
var atlas_sizes = null
var inverse_scale_factor = null
var entity_center = Vector3.ZERO

func _run(context) -> Dictionary:
	# Fetch context data
	var brush_data_dict = context['brush_data_dict']
	var entity_definition_set = context['entity_definition_set']
	var entity_properties_array = context['entity_properties_array']
	var texture_atlas = context['texture_atlas']
	self.inverse_scale_factor = context['inverse_scale_factor']

	# Fetch subdata
	var atlas_textures = texture_atlas['atlas_textures']
	var atlas_data_texture = texture_atlas['atlas_data_texture']
	self.atlas_texture_names = texture_atlas['atlas_texture_names']
	self.atlas_sizes = texture_atlas['atlas_sizes']

	var atlas_shader_material = preload('res://addons/qodot/shaders/atlas.tres').duplicate()

	# Build brush geometry
	var array_mesh_dict = {}
	var texture_layered_mesh_dict = {}
	var texture_layered_mesh_nodes = {}
	for entity_idx in brush_data_dict:
		var entity_properties = entity_properties_array[entity_idx]

		if not 'classname' in entity_properties:
			continue

		var classname = entity_properties['classname']
		var entity_definition = entity_definition_set[classname]

		var brush_data = brush_data_dict[entity_idx]

		var surface_tool = SurfaceTool.new()
		surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		entity_surface_tools[entity_idx] = surface_tool

		entity_center = Vector3.ZERO
		for brush_idx in brush_data:
			var brush = create_brush_from_face_data(brush_data[brush_idx])
			entity_center += brush.center
		entity_center /= brush_data.size()

		var results = foreach_brush_face(
			entity_definition_set,
			entity_idx,
			entity_properties_array[entity_idx],
			brush_data_dict[entity_idx],
			funcref(self, 'should_spawn_brush_mesh'),
			funcref(self, 'should_spawn_face_mesh'),
			funcref(self, 'get_face_mesh')
		)

		var array_meshes = {}

		if results.size() > 0:
			surface_tool.index()
			array_meshes[entity_idx] = ArrayMesh.new()
		else:
			entity_surface_tools.erase(entity_idx)
			continue

		# Create TextureLayeredMesh
		var texture_layered_mesh = null
		if entity_definition.spawn_type != QodotFGDSolidClass.SpawnType.MERGE_WORLDSPAWN:
			texture_layered_mesh = QodotTextureLayeredMesh.new()
			texture_layered_mesh.set_shader_parameter('atlas_array')
			texture_layered_mesh.set_texture_format(QodotTextureLayeredMesh.TextureFormat.RGB8)
			texture_layered_mesh.set_shader_material(atlas_shader_material)
			texture_layered_mesh.set_array_data(atlas_textures)
			texture_layered_mesh.shader_material.set_shader_param('atlas_data', atlas_data_texture)
			texture_layered_mesh.name = 'visuals_atlased'
		else:
			texture_layered_mesh = texture_layered_mesh_dict[0]

		texture_layered_mesh.set_meshes(texture_layered_mesh.meshes + array_meshes.values())

		array_mesh_dict[entity_idx] = array_meshes
		texture_layered_mesh_dict[entity_idx] = texture_layered_mesh

		var entity_key = null
		if entity_definition.spawn_type == QodotFGDSolidClass.SpawnType.ENTITY:
			entity_key = get_entity_key(entity_idx)
		else:
			entity_key = get_entity_key(0)

		if not entity_key in texture_layered_mesh_nodes:
			texture_layered_mesh_nodes[entity_key] = {}

		if entity_definition.physics_body_type == QodotFGDSolidClass.PhysicsBodyType.NONE:
			texture_layered_mesh_nodes[entity_key] = {
				'atlased_mesh': texture_layered_mesh
			}
		else:
			texture_layered_mesh_nodes[entity_key] = {
				'entity_physics_body': {
					'atlased_mesh': texture_layered_mesh
				}
			}

	return {
		'brush_entity_atlased_meshes': {
			'texture_layered_mesh_nodes': texture_layered_mesh_nodes,
			'texture_layered_mesh_dict': texture_layered_mesh_dict,
			'array_mesh_dict': array_mesh_dict,
			'atlased_surfaces': entity_surface_tools
		}
	}

func get_face_mesh(entity_key, entity_definitions: Dictionary, entity_properties: Dictionary, brush_key, brush: QuakeBrush, face_idx, face: QuakeFace):
	var texture_idx = atlas_texture_names.find(face.texture)

	if not 'classname' in entity_properties:
		return false

	var classname = entity_properties['classname']
	var entity_definition = entity_definitions[classname]

	var offset = Vector3.ZERO
	if entity_definition.spawn_type == QodotFGDSolidClass.SpawnType.ENTITY:
		offset = face.center - entity_center
	else:
		offset = face.center

	var atlas_size = atlas_sizes[texture_idx] / inverse_scale_factor
	var texture_vertex_color = Color()
	texture_vertex_color.r = float(texture_idx) / float(atlas_texture_names.size() - 1)
	face.get_mesh(entity_surface_tools[entity_key], atlas_size, texture_vertex_color, offset, should_smooth_face_normals(entity_properties))

	return true

func _finalize(context: Dictionary) -> Dictionary:
	var brush_entity_atlased_meshes = context['brush_entity_atlased_meshes']

	var texture_layered_mesh_nodes = brush_entity_atlased_meshes['texture_layered_mesh_nodes']
	var texture_layered_mesh_dict = brush_entity_atlased_meshes['texture_layered_mesh_dict']
	var array_mesh_dict = brush_entity_atlased_meshes['array_mesh_dict']
	var atlased_surfaces = brush_entity_atlased_meshes['atlased_surfaces']

	for texture_layered_mesh_key in texture_layered_mesh_dict:
		var texture_layered_mesh = texture_layered_mesh_dict[texture_layered_mesh_key]

		texture_layered_mesh.call_deferred('set_reload', true)

	var meshes_to_unwrap = {}
	for array_mesh_key in array_mesh_dict:
		var array_mesh = array_mesh_dict[array_mesh_key]
		for entity_idx in array_mesh:
			var atlased_mesh = array_mesh[entity_idx]
			var atlased_surface = atlased_surfaces[entity_idx]
			atlased_surface.commit(atlased_mesh)
			meshes_to_unwrap[entity_idx] = atlased_mesh

	return {
		'nodes': {
			'brush_entities_node': texture_layered_mesh_nodes
		},
		'meshes_to_unwrap': meshes_to_unwrap
	}
