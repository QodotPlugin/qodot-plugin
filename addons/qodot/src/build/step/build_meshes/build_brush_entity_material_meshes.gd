class_name QodotBuildBrushEntityMaterialMeshes
extends QodotBuildMeshes

func get_name() -> String:
	return "brush_entity_material_meshes"

func get_type() -> int:
	return self.Type.SINGLE

func get_build_params() -> Array:
	return ['entity_centers', 'entity_definition_set', 'entity_properties_array', 'brush_data_dict', 'material_dict', 'inverse_scale_factor']

func get_wants_finalize():
	return true

func get_finalize_params() -> Array:
	return ['entity_definition_set', 'entity_properties_array', 'brush_entity_material_meshes']

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

		return entity_definition.visual_build_type == QodotFGDSolidClass.VisualBuildType.MATERIAL_MESHES

	# Should never reach here
	return false

var entity_material_names = {}
var entity_material_index_paths = {}

func _run(context) -> Dictionary:
	# Fetch context variables
	var entity_centers = context['entity_centers']
	var entity_definition_set = context['entity_definition_set']
	var entity_properties_array = context['entity_properties_array']
	var brush_data_dict = context['brush_data_dict']
	var material_dict = context['material_dict']
	var inverse_scale_factor = context['inverse_scale_factor']

	foreach_entity_brush_face(
		entity_definition_set,
		entity_properties_array,
		brush_data_dict,
		funcref(self, 'boolean_true'),
		funcref(self, 'should_spawn_brush_mesh'),
		funcref(self, 'should_spawn_face_mesh'),
		funcref(self, 'get_entity_material_name_and_index_path')
	)

	# Create one surface per material
	var entity_material_surfaces = {}
	for entity_idx in entity_material_names:
		var material_names = entity_material_names[entity_idx]
		var entity_properties = entity_properties_array[entity_idx]

		if not 'classname' in entity_properties:
			continue

		var classname = entity_properties['classname']
		var entity_definition = entity_definition_set[classname]

		for material_name in material_names:
			if entity_definition.spawn_type != QodotFGDSolidClass.SpawnType.MERGE_WORLDSPAWN:
				if not entity_idx in entity_material_surfaces:
					entity_material_surfaces[entity_idx] = {}

				if not material_name in entity_material_surfaces[entity_idx]:
					var surface_tool = SurfaceTool.new()
					surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
					entity_material_surfaces[entity_idx][material_name] = surface_tool
			else:
				if not 0 in entity_material_surfaces:
					entity_material_surfaces[0] = {}

				if not material_name in entity_material_surfaces[0]:
					var surface_tool = SurfaceTool.new()
					surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
					entity_material_surfaces[0][material_name] = surface_tool

	for entity_idx in entity_material_names:
		var entity_properties = entity_properties_array[entity_idx]

		if not 'classname' in entity_properties:
			continue

		var classname = entity_properties['classname']
		var entity_definition = entity_definition_set[classname]

		var brush_data = brush_data_dict[entity_idx]

		var entity_center = entity_centers[entity_idx]
		var brushes = []
		for brush_idx in brush_data:
			var brush = create_brush_from_face_data(brush_data[brush_idx])
			brushes.append(brush)

		var material_names = entity_material_names[entity_idx]
		for material_name in material_names:
			var surface_tool = null

			if entity_definition.spawn_type != QodotFGDSolidClass.SpawnType.MERGE_WORLDSPAWN:
				surface_tool = entity_material_surfaces[entity_idx][material_name]
			else:
				surface_tool = entity_material_surfaces[0][material_name]

			var face_index_paths = entity_material_index_paths[entity_idx][material_name]
			for face_index_path in face_index_paths:
				var face_entity_idx = face_index_path[0]
				var brush_idx = face_index_path[1]
				var face_idx = face_index_path[2]
				var face_data = brush_data_dict[face_entity_idx][brush_idx]

				var brush = brushes[brush_idx]
				var face = brush.faces[face_idx]

				var texture_size = Vector2.ZERO

				var material = material_dict[face.texture]
				if material:
					surface_tool.set_material(material)

					var albedo_texture = material.get_texture(SpatialMaterial.TEXTURE_ALBEDO)
					texture_size = albedo_texture.get_size() / inverse_scale_factor

				var offset = null
				if entity_definition.spawn_type == QodotFGDSolidClass.SpawnType.ENTITY:
					offset = face.center - entity_center
				else:
					offset = face.center

				face.get_mesh(surface_tool, texture_size, Color.white, offset, should_smooth_face_normals(entity_properties_array[entity_idx]))

	for entity_idx in entity_material_surfaces:
		for material_name in entity_material_surfaces[entity_idx]:
			entity_material_surfaces[entity_idx][material_name].index()

	# Return data for surface committing on the main thread
	return {
		'brush_entity_material_meshes': {
			'entity_material_surfaces': entity_material_surfaces
		}
	}

func get_entity_material_name_and_index_path(entity_key, entity_definitions, entity_properties, brush_key, brush, face_idx, face):
	if not entity_key in entity_material_names:
		entity_material_names[entity_key] = []

	if not face.texture in entity_material_names[entity_key]:
		entity_material_names[entity_key].append(face.texture)

	if not entity_key in entity_material_index_paths:
		entity_material_index_paths[entity_key] = {}

	if not face.texture in entity_material_index_paths[entity_key]:
		entity_material_index_paths[entity_key][face.texture] = []

	entity_material_index_paths[entity_key][face.texture].append([entity_key, brush_key, face_idx])

func _finalize(context) -> Dictionary:
	# Fetch context data
	var entity_definition_set = context['entity_definition_set']
	var entity_properties_array = context['entity_properties_array']
	var brush_entity_material_meshes = context['brush_entity_material_meshes']

	# Fetch subdata
	var entity_material_surfaces = brush_entity_material_meshes['entity_material_surfaces']

	var array_meshes = {}
	var materials_nodes = {}

	for entity_idx in entity_material_surfaces:
		var entity_properties = entity_properties_array[entity_idx]

		if not 'classname' in entity_properties:
			continue

		var classname = entity_properties['classname']
		var entity_definition = entity_definition_set[classname]

		var material_surfaces = entity_material_surfaces[entity_idx]

		var entity_key = null
		if entity_definition.spawn_type == QodotFGDSolidClass.SpawnType.ENTITY:
			entity_key = get_entity_key(entity_idx)
		else:
			entity_key = get_entity_key(0)

		# Create single array mesh
		var array_mesh = ArrayMesh.new()
		array_meshes[entity_key] = array_mesh

		# Commit material surfaces to array mesh
		for material_name in material_surfaces:
			var material_surface = material_surfaces[material_name]
			material_surface.commit(array_mesh)

		# Create MeshInstance, configure, and apply mesh
		var materials_node = MeshInstance.new()
		materials_node.name = 'visuals_materials'

		materials_node.set_flag(MeshInstance.FLAG_USE_BAKED_LIGHT, true)
		materials_node.set_mesh(array_mesh)

		if not entity_key in materials_nodes:
			materials_nodes[entity_key] = {}

		if entity_definition.physics_body_type == QodotFGDSolidClass.PhysicsBodyType.NONE:
			materials_nodes[entity_key] = {
				'materials_node': materials_node
			}
		else:
			materials_nodes[entity_key] = {
				'entity_physics_body': {
					'materials_node': materials_node
				}
			}

	var node_dict = {
		'brush_entities_node': materials_nodes
	}

	return {
		'meshes_to_unwrap': array_meshes,
		'nodes': node_dict
	}
