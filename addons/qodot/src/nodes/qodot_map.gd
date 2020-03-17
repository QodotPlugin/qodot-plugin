class_name QodotMap
extends QodotSpatial
tool

const DEBUG := false
const YIELD_DURATION = 0.0
const YIELD_SIGNAL = "timeout"

enum QodotMapAction {
	SELECT_AN_ACTION,
	QUICK_BUILD,
	FULL_BUILD,
	UNWRAP_UV2
}

signal build_complete(entity_nodes)
signal build_failed()

export(QodotMapAction) var action  setget set_action
export(bool) var print_profiling_data := false
export(String) var map := QodotUtil.CATEGORY_STRING
export(String, FILE, GLOBAL, "*.map") var map_file setget set_map_file
export(float) var inverse_scale_factor = 16.0
export(String) var entities := QodotUtil.CATEGORY_STRING
export(Resource) var entity_fgd = preload("res://addons/qodot/game-definitions/fgd/qodot_fgd.tres")
export(String) var textures := QodotUtil.CATEGORY_STRING
export(String, DIR) var base_texture_dir := "res://textures"
export(String) var texture_file_extension := ".png"

export(Array, Dictionary) var worldspawn_layers := [
	{
		"name": "water",
		"texture": "special/water",
		"node_class": "Area",
		"build_visuals": true,
		"collision_shape_type": 1,
		"script_class": preload("res://game-definitions/fgd/solid_classes/water.gd")
	}
]

export(String) var brush_clip_texture := "special/clip"
export(String) var face_skip_texture := "special/skip"
export(Array, Resource) var texture_wads := []
export(String) var materials := QodotUtil.CATEGORY_STRING
export(String) var material_file_extension := ".tres"
export(SpatialMaterial) var default_material = SpatialMaterial.new()
export(String) var uv_unwrap := QodotUtil.CATEGORY_STRING
export(float) var uv_unwrap_texel_size := 1.0
export(String) var build := QodotUtil.CATEGORY_STRING
export(int) var tree_attach_batch_size := 16
export(int) var set_owner_batch_size := 16

# Build context variables
var qodot = null

var profile_timestamps = {}

var add_child_array = []
var set_owner_array = []

var cached_name = null
var should_add_children := true
var should_set_owners := true

var texture_list := []
var texture_loader = null
var texture_dict := {}
var texture_size_dict := {}
var material_dict := {}
var entity_definitions := {}
var entity_dicts := []
var worldspawn_layer_dicts := []
var entity_mesh_dict := {}
var worldspawn_layer_mesh_dict := {}
var entity_nodes := []
var worldspawn_layer_nodes := []
var entity_mesh_instances := {}
var worldspawn_layer_mesh_instances := {}
var entity_collision_shapes := []
var worldspawn_layer_collision_shapes := []

func set_action(new_action) -> void:
	if action != new_action:
		match new_action:
			QodotMapAction.QUICK_BUILD:
				should_add_children = true
				should_set_owners = false
				verify_and_build()
			QodotMapAction.FULL_BUILD:
				should_add_children = true
				should_set_owners = true
				verify_and_build()
			QodotMapAction.UNWRAP_UV2:
				print("Unwrapping mesh UV2s\n")
				unwrap_uv2(self)
				print("Unwrap complete\n")

func set_map_file(new_map_file: String) -> void:
	if map_file != new_map_file:
		map_file = new_map_file

func _ready() -> void:
	if not DEBUG:
		return

	if not Engine.is_editor_hint():
		if verify_parameters():
			build_map()

# Utility
func verify_and_build():
	if verify_parameters():
		build_map()
	else:
		emit_signal("build_failed")

func manual_build():
	should_add_children = false
	should_set_owners = false
	verify_and_build()

func verify_parameters():
	if not qodot:
		var lib_qodot := load("res://addons/qodot/bin/qodot.gdns")
		if lib_qodot:
			qodot = lib_qodot.new()

	if not qodot:
		push_error("Error: Failed to load libqodot")
		return false

	if map_file == "":
		push_error("Error: Map file not set")
		return false

	var map = File.new()
	if not map.file_exists(map_file):
		push_error("Error: No such file %s" % map_file)
		return false

	return true

func reset_build_context():
	texture_list = []
	texture_loader = null
	texture_dict = {}
	texture_size_dict = {}
	material_dict = {}
	entity_definitions = {}
	worldspawn_layer_dicts = []
	entity_dicts = []
	entity_nodes = []
	entity_mesh_instances = {}
	entity_collision_shapes = []
	entity_mesh_dict = {}

	add_child_array = []
	set_owner_array = []

	cached_name = null

func start_profile(item_name: String) -> void:
	name = "%s [%s]" % [cached_name, item_name]
	if print_profiling_data:
		print(item_name)
		profile_timestamps[item_name] = OS.get_ticks_usec()

func stop_profile(item_name: String) -> void:
	if print_profiling_data:
		if item_name in profile_timestamps:
			var delta = OS.get_ticks_usec() - profile_timestamps[item_name]
			print("Done in %s sec\n" % [delta * 0.000001])
			profile_timestamps.erase(item_name)

func run_build_step(step_name: String, params: Array = [], func_name: String = ""):
	start_profile(step_name)
	if func_name == "":
		func_name = step_name
	var result = funcref(self, func_name).call_funcv(params)
	stop_profile(step_name)
	return result

func add_child_editor(parent, node, below = null) -> void:
	var prev_parent = node.get_parent()
	if prev_parent:
		prev_parent.remove_child(node)

	if below:
		parent.add_child_below_node(below, node)
	else:
		parent.add_child(node)

	set_owner_array.append(node)

func set_owner_editor(node):
	var tree := get_tree()

	if not tree:
		return

	var edited_scene_root := tree.get_edited_scene_root()

	if not edited_scene_root:
		return

	node.set_owner(edited_scene_root)

# Actions
func build_map() -> void:
	reset_build_context()

	cached_name = name

	print('Building %s\n' % map_file)
	start_profile('build_map')

	run_build_step('remove_children')
	yield(get_tree().create_timer(YIELD_DURATION), YIELD_SIGNAL)

	run_build_step('load_map', [map_file])
	yield(get_tree().create_timer(YIELD_DURATION), YIELD_SIGNAL)

	var texture_list := run_build_step('fetch_texture_list') as Array
	yield(get_tree().create_timer(YIELD_DURATION), YIELD_SIGNAL)

	var texture_loader := run_build_step('init_texture_loader') as QodotTextureLoader
	yield(get_tree().create_timer(YIELD_DURATION), YIELD_SIGNAL)

	var texture_dict := run_build_step('load_textures', [texture_loader, texture_list]) as Dictionary
	yield(get_tree().create_timer(YIELD_DURATION), YIELD_SIGNAL)

	var texture_size_dict := run_build_step('build_texture_size_dict', [texture_dict]) as Dictionary
	yield(get_tree().create_timer(YIELD_DURATION), YIELD_SIGNAL)

	var material_dict := run_build_step('build_materials', [texture_loader, texture_list]) as Dictionary
	yield(get_tree().create_timer(YIELD_DURATION), YIELD_SIGNAL)

	# Load entity definitions
	if entity_fgd:
		entity_definitions = run_build_step('fetch_entity_definitions')
		yield(get_tree().create_timer(YIELD_DURATION), YIELD_SIGNAL)

	# Send entity definitions to libmap
	run_build_step('set_entity_definitions', [entity_definitions])
	yield(get_tree().create_timer(YIELD_DURATION), YIELD_SIGNAL)

	# Send worldspawn layers to libmap
	run_build_step('set_worldspawn_layers', [worldspawn_layers])
	yield(get_tree().create_timer(YIELD_DURATION), YIELD_SIGNAL)

	# Generate geometry
	run_build_step('generate_geometry', [texture_size_dict])
	yield(get_tree().create_timer(YIELD_DURATION), YIELD_SIGNAL)

	# Get entity metadata
	entity_dicts = run_build_step('fetch_entity_dicts') as Array
	yield(get_tree().create_timer(YIELD_DURATION), YIELD_SIGNAL)

	# Get worldspawn layer metadata
	worldspawn_layer_dicts = run_build_step('fetch_worldspawn_layer_dicts') as Array
	yield(get_tree().create_timer(YIELD_DURATION), YIELD_SIGNAL)

	entity_nodes = run_build_step('build_entity_nodes', [entity_dicts, entity_definitions]) as Array
	yield(get_tree().create_timer(YIELD_DURATION), YIELD_SIGNAL)

	worldspawn_layer_nodes = run_build_step('build_worldspawn_layer_nodes', [entity_nodes, worldspawn_layers]) as Array
	yield(get_tree().create_timer(YIELD_DURATION), YIELD_SIGNAL)

	run_build_step('resolve_group_hierarchy', [entity_nodes, entity_dicts, entity_definitions])
	yield(get_tree().create_timer(YIELD_DURATION), YIELD_SIGNAL)

	entity_mesh_dict = run_build_step('build_entity_mesh_dict', [texture_dict, material_dict, entity_dicts, entity_definitions]) as Dictionary
	yield(get_tree().create_timer(YIELD_DURATION), YIELD_SIGNAL)

	worldspawn_layer_mesh_dict = run_build_step('build_worldspawn_layer_mesh_dict', [texture_dict, material_dict, worldspawn_layer_dicts]) as Dictionary
	yield(get_tree().create_timer(YIELD_DURATION), YIELD_SIGNAL)

	entity_mesh_instances = run_build_step('build_entity_mesh_instances', [
		entity_mesh_dict,
		entity_dicts,
		entity_definitions,
		entity_nodes
	])
	yield(get_tree().create_timer(YIELD_DURATION), YIELD_SIGNAL)

	worldspawn_layer_mesh_instances = run_build_step('build_worldspawn_layer_mesh_instances', [
		worldspawn_layers,
		worldspawn_layer_mesh_dict,
		worldspawn_layer_nodes
	])
	yield(get_tree().create_timer(YIELD_DURATION), YIELD_SIGNAL)

	entity_collision_shapes = run_build_step('build_entity_collision_shape_nodes', [
		entity_dicts, entity_definitions, entity_nodes
	]) as Array
	yield(get_tree().create_timer(YIELD_DURATION), YIELD_SIGNAL)

	worldspawn_layer_collision_shapes = run_build_step('build_worldspawn_layer_collision_shape_nodes', [
		worldspawn_layers, worldspawn_layer_dicts, worldspawn_layer_nodes
	])
	yield(get_tree().create_timer(YIELD_DURATION), YIELD_SIGNAL)

	print(worldspawn_layer_collision_shapes)

	start_profile('add_children')
	add_children()

func unwrap_uv2(node: Node) -> void:
	if node is MeshInstance:
		var mesh = node.get_mesh()
		if mesh is ArrayMesh:
			mesh.lightmap_unwrap(Transform.IDENTITY, uv_unwrap_texel_size / inverse_scale_factor)

	for child in node.get_children():
		unwrap_uv2(child)

# Build Steps

func remove_children() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

func load_map(map_file: String) -> void:
	qodot.load_map(map_file)

func fetch_texture_list() -> Array:
	return qodot.get_texture_list() as Array

func init_texture_loader() -> QodotTextureLoader:
	return QodotTextureLoader.new(
		base_texture_dir,
		texture_file_extension,
		texture_wads
	)

func load_textures(texture_loader: QodotTextureLoader, texture_list: Array) -> Dictionary:
	return texture_loader.load_textures(texture_list) as Dictionary

func build_materials(texture_loader: QodotTextureLoader, texture_list: Array) -> Dictionary:
	return texture_loader.create_materials(texture_list, material_file_extension, default_material)

func fetch_entity_definitions() -> Dictionary:
	return entity_fgd.get_entity_definitions()

func set_entity_definitions(entity_definitions: Dictionary) -> void:
	qodot.set_entity_definitions(build_libmap_entity_definitions(entity_definitions))

func set_worldspawn_layers(worldspawn_layers: Array) -> void:
	qodot.set_worldspawn_layers(worldspawn_layers)

func generate_geometry(texture_size_dict: Dictionary) -> void:
	qodot.generate_geometry(texture_size_dict);

func fetch_entity_dicts() -> Array:
	return qodot.get_entity_dicts()

func fetch_worldspawn_layer_dicts() -> Array:
	return qodot.get_worldspawn_layer_dicts()

func build_texture_size_dict(texture_dict: Dictionary) -> Dictionary:
	var texture_size_dict := {}

	for tex_key in texture_dict:
		var texture := texture_dict[tex_key] as Texture
		if texture:
			texture_size_dict[tex_key] = texture.get_size()
		else:
			texture_size_dict[tex_key] = Vector2.ONE

	return texture_size_dict

func build_libmap_entity_definitions(entity_definitions: Dictionary) -> Dictionary:
	var libmap_entity_definitions = {}
	for classname in entity_definitions:
		libmap_entity_definitions[classname] = {}
		if entity_definitions[classname] is QodotFGDSolidClass:
			libmap_entity_definitions[classname]['spawn_type'] = entity_definitions[classname].spawn_type
	return libmap_entity_definitions

func build_entity_nodes(entity_dicts: Array, entity_definitions: Dictionary) -> Array:
	var entity_nodes := []

	for entity_idx in range(0, entity_dicts.size()):
		var entity_dict := entity_dicts[entity_idx] as Dictionary
		var properties := entity_dict['properties'] as Dictionary

		var node = QodotEntity.new()
		var node_name = "entity_%s" % entity_idx

		var should_add_child = should_add_children

		if 'classname' in properties:
			var classname = properties['classname']
			node_name += "_" + classname
			if classname in entity_definitions:
				var entity_definition := entity_definitions[classname] as QodotFGDClass
				if entity_definition is QodotFGDSolidClass:
					if entity_definition.spawn_type == QodotFGDSolidClass.SpawnType.MERGE_WORLDSPAWN:
						entity_nodes.append(null)
						continue
					elif entity_definition.spawn_type == QodotFGDSolidClass.SpawnType.GROUP:
						should_add_child = false
					if entity_definition.node_class != "":
						node = ClassDB.instance(entity_definition.node_class)
				elif entity_definition is QodotFGDPointClass:
					if entity_definition.scene_file:
						node = entity_definition.scene_file.instance(PackedScene.GEN_EDIT_STATE_INSTANCE)

				if entity_definition.script_class:
					node.set_script(entity_definition.script_class)

		node.name = node_name

		if 'origin' in properties:
			var origin_comps = properties['origin'].split(' ')
			var origin_vec = Vector3(origin_comps[1].to_float(), origin_comps[2].to_float(), origin_comps[0].to_float())
			node.translation = origin_vec / inverse_scale_factor
		else:
			if entity_idx != 0:
				node.translation = entity_dict['center'] / inverse_scale_factor

		entity_nodes.append(node)

		if should_add_child:
			queue_add_child(self, node)

	return entity_nodes

func build_worldspawn_layer_nodes(entity_nodes: Array, worldspawn_layers: Array) -> Array:
	var worldspawn_layer_nodes := []

	for worldspawn_layer in worldspawn_layers:
		var node = ClassDB.instance(worldspawn_layer['node_class'])
		node.name = "entity_0_" + worldspawn_layer['name']
		if worldspawn_layer.script_class:
			node.set_script(worldspawn_layer.script_class)

		worldspawn_layer_nodes.append(node)
		queue_add_child(self, node, entity_nodes[0])

	return worldspawn_layer_nodes

func resolve_group_hierarchy(entity_nodes: Array, entity_dicts: Array, entity_definitions: Dictionary) -> void:
	var group_entities := {}
	var owner_entities := {}

	# Gather group entities and their owning children
	for node_idx in range(0, entity_nodes.size()):
		var node = entity_nodes[node_idx]
		var properties = entity_dicts[node_idx]['properties']

		if not properties: continue

		if not '_tb_id' in properties and not '_tb_group' in properties:
			continue

		if not 'classname' in properties: continue
		var classname = properties['classname']

		if not classname in entity_definitions: continue
		var entity_definition = entity_definitions[classname]

		if entity_definition.spawn_type == QodotFGDSolidClass.SpawnType.GROUP:
			group_entities[node_idx] = node
		else:
			owner_entities[node_idx] = node

	var group_to_entity_map := {}

	for node_idx in owner_entities:
		var node = owner_entities[node_idx]
		var properties = entity_dicts[node_idx]['properties']
		var tb_group = properties['_tb_group']

		var parent_idx = null
		var parent = null
		var parent_properties = null
		for group_idx in group_entities:
			var group_entity = group_entities[group_idx]
			var group_properties = entity_dicts[group_idx]['properties']
			if group_properties['_tb_id'] == tb_group:
				parent_idx = group_idx
				parent = group_entity
				parent_properties = group_properties
				break

		if parent:
			group_to_entity_map[parent_idx] = node_idx

	var group_to_group_map := {}

	for node_idx in group_entities:
		var node = group_entities[node_idx]
		var properties = entity_dicts[node_idx]['properties']

		if not '_tb_group' in properties:
			continue

		var tb_group = properties['_tb_group']

		var parent_idx = null
		var parent = null
		var parent_properties = null
		for group_idx in group_entities:
			var group_entity = group_entities[group_idx]
			var group_properties = entity_dicts[group_idx]['properties']
			if group_properties['_tb_id'] == tb_group:
				parent_idx = group_idx
				parent = group_entity
				parent_properties = group_properties
				break

		if parent:
			group_to_group_map[parent_idx] = node_idx

	for parent_idx in group_to_group_map:
		var child_idx = group_to_group_map[parent_idx]

		var parent_entity_idx = group_to_entity_map[parent_idx]
		var child_entity_idx = group_to_entity_map[child_idx]

		var parent = entity_nodes[parent_entity_idx]
		var child = entity_nodes[child_entity_idx]

		queue_add_child(parent, child, null, true)

	for child_idx in group_to_entity_map:
		var parent_idx = group_to_entity_map[child_idx]

		var parent = entity_nodes[parent_idx]
		var child = entity_nodes[child_idx]

		queue_add_child(parent, child, null, true)

func get_node_by_tb_id(target_id: String, entity_nodes: Dictionary):
	for node_idx in entity_nodes:
		var node = entity_nodes[node_idx]

		if not node:
			continue

		if not 'properties' in node:
			continue

		var properties = node['properties']

		if not '_tb_id' in properties:
			continue

		var parent_id = properties['_tb_id']
		if parent_id == target_id:
			return node

	return null

func build_entity_collision_shape_nodes(entity_dicts: Array, entity_definitions: Dictionary, entity_nodes: Array) -> Array:
	var entity_collision_shapes_arr := []

	for entity_idx in range(0, entity_nodes.size()):
		var entity_collision_shapes := []

		var entity_dict = entity_dicts[entity_idx]
		var properties = entity_dict['properties']

		var node := entity_nodes[entity_idx] as Node
		var concave = false

		if 'classname' in properties:
			var classname = properties['classname']
			if classname in entity_definitions:
				var entity_definition := entity_definitions[classname] as QodotFGDSolidClass
				if entity_definition:
					if entity_definition.collision_shape_type == QodotFGDSolidClass.CollisionShapeType.NONE:
						entity_collision_shapes_arr.append(null)
						continue
					elif entity_definition.collision_shape_type == QodotFGDSolidClass.CollisionShapeType.CONCAVE:
						concave = true

					if entity_definition.spawn_type == QodotFGDSolidClass.SpawnType.MERGE_WORLDSPAWN:
						# TODO: Find the worldspawn object instead of assuming index 0
						node = entity_nodes[0] as Node

		if not node:
			entity_collision_shapes_arr.append(null)
			continue

		if concave:
			var collision_shape := CollisionShape.new()
			collision_shape.name = "entity_%s_collision_shape" % entity_idx
			entity_collision_shapes.append(collision_shape)
			queue_add_child(node, collision_shape)
		else:
			for brush_idx in entity_dict['brush_indices']:
				var collision_shape := CollisionShape.new()
				collision_shape.name = "entity_%s_brush_%s_collision_shape" % [entity_idx, brush_idx]
				entity_collision_shapes.append(collision_shape)
				queue_add_child(node, collision_shape)

		entity_collision_shapes_arr.append(entity_collision_shapes)

	return entity_collision_shapes_arr

func build_worldspawn_layer_collision_shape_nodes(worldspawn_layers: Array, worldspawn_layer_dicts: Array, worldspawn_layer_nodes: Array) -> Array:
	var worldspawn_layer_collision_shapes := []

	for layer_idx in range(0, worldspawn_layers.size()):
		var layer = worldspawn_layers[layer_idx]
		var layer_dict = worldspawn_layer_dicts[layer_idx]
		var node := worldspawn_layer_nodes[layer_idx] as Node
		var concave = false

		if layer['collision_shape_type'] == QodotFGDSolidClass.CollisionShapeType.NONE:
			worldspawn_layer_collision_shapes.append(null)
			continue
		elif layer['collision_shape_type'] == QodotFGDSolidClass.CollisionShapeType.CONCAVE:
			concave = true

		if not node:
			worldspawn_layer_collision_shapes.append(null)
			continue

		if concave:
			var collision_shape := CollisionShape.new()
			collision_shape.name = "entity_0_%s_collision_shape" % layer['name']
			worldspawn_layer_collision_shapes.append(collision_shape)
			queue_add_child(node, collision_shape)
		else:
			for brush_idx in layer_dict['brush_indices']:
				var collision_shape := CollisionShape.new()
				collision_shape.name = "entity_0_%s_brush_%s_collision_shape" % [layer['name'], brush_idx]
				worldspawn_layer_collision_shapes.append(collision_shape)
				queue_add_child(node, collision_shape)

	return worldspawn_layer_collision_shapes

func build_entity_collision_shapes(entity_dicts: Array, entity_definitions: Dictionary, entity_collision_shapes: Array) -> void:
	for entity_idx in range(0, entity_dicts.size()):
		var entity_dict := entity_dicts[entity_idx] as Dictionary
		var properties = entity_dict['properties']

		var concave = false

		if 'classname' in properties:
			var classname = properties['classname']
			if classname in entity_definitions:
				var entity_definition = entity_definitions[classname] as QodotFGDSolidClass
				if entity_definition:
					match(entity_definition.collision_shape_type):
						QodotFGDSolidClass.CollisionShapeType.NONE:
							continue
						QodotFGDSolidClass.CollisionShapeType.CONVEX:
							concave = false
						QodotFGDSolidClass.CollisionShapeType.CONCAVE:
							concave = true

		if not entity_collision_shapes[entity_idx]:
			continue

		if concave:
			qodot.gather_entity_concave_collision_surfaces(entity_idx)
		else:
			qodot.gather_entity_convex_collision_surfaces(entity_idx)

		var entity_surfaces := qodot.fetch_surfaces(inverse_scale_factor) as Array

		var entity_verts := PoolVector3Array()

		for surface_idx in range(0, entity_surfaces.size()):
			var surface_verts = entity_surfaces[surface_idx]

			if not surface_verts:
				continue

			if concave:
				var vertices := surface_verts[0] as PoolVector3Array
				var indices := surface_verts[8] as PoolIntArray
				for vert_idx in indices:
					entity_verts.append(vertices[vert_idx])
			else:
				var shape_points = PoolVector3Array()
				for vertex in surface_verts[0]:
					if not vertex in shape_points:
						shape_points.append(vertex)

				var shape = ConvexPolygonShape.new()
				shape.set_points(shape_points)

				var collision_shape = entity_collision_shapes[entity_idx][surface_idx]
				collision_shape.set_shape(shape)

		if concave:
			if entity_verts.size() == 0:
				continue

			var shape = ConcavePolygonShape.new()
			shape.set_faces(entity_verts)

			var collision_shape = entity_collision_shapes[entity_idx][0]
			collision_shape.set_shape(shape)

func build_worldspawn_layer_collision_shapes(worldspawn_layers: Array, worldspawn_layer_dicts: Array, worldspawn_layer_collision_shapes: Array) -> void:
	for layer_idx in range(0, worldspawn_layers.size()):
		var layer = worldspawn_layers[layer_idx]
		var concave = false

		match(layer['collision_shape_type']):
			QodotFGDSolidClass.CollisionShapeType.NONE:
				continue
			QodotFGDSolidClass.CollisionShapeType.CONVEX:
				concave = false
			QodotFGDSolidClass.CollisionShapeType.CONCAVE:
				concave = true

		var layer_dict = worldspawn_layer_dicts[layer_idx]

		if not worldspawn_layer_collision_shapes[layer_idx]:
			continue

		if concave:
			qodot.gather_worldspawn_layer_concave_collision_surfaces(0)
		else:
			qodot.gather_worldspawn_layer_convex_collision_surfaces(0)

		var layer_surfaces := qodot.fetch_surfaces(inverse_scale_factor) as Array

		var verts := PoolVector3Array()

		for surface_idx in range(0, layer_surfaces.size()):
			var surface_verts = layer_surfaces[surface_idx]

			if not surface_verts:
				continue

			if concave:
				var vertices := surface_verts[0] as PoolVector3Array
				var indices := surface_verts[8] as PoolIntArray
				for vert_idx in indices:
					verts.append(vertices[vert_idx])
			else:
				var shape_points = PoolVector3Array()
				for vertex in surface_verts[0]:
					if not vertex in shape_points:
						shape_points.append(vertex)

				var shape = ConvexPolygonShape.new()
				shape.set_points(shape_points)

				var collision_shape = worldspawn_layer_collision_shapes[layer_idx]
				collision_shape.set_shape(shape)

		if concave:
			if verts.size() == 0:
				continue

			var shape = ConcavePolygonShape.new()
			shape.set_faces(verts)

			var collision_shape = worldspawn_layer_collision_shapes[layer_idx]
			collision_shape.set_shape(shape)

func build_entity_mesh_dict(texture_dict: Dictionary, material_dict: Dictionary, entity_dicts: Array, entity_definitions: Dictionary) -> Dictionary:
	var meshes := {}

	for texture in texture_dict:
		qodot.gather_texture_surfaces(texture, brush_clip_texture, face_skip_texture)
		var texture_surfaces := qodot.fetch_surfaces(inverse_scale_factor) as Array

		for entity_idx in range(0, texture_surfaces.size()):
			var entity_dict := entity_dicts[entity_idx] as Dictionary
			var properties = entity_dict['properties']

			var entity_surface = texture_surfaces[entity_idx]

			if 'classname' in properties:
				var classname = properties['classname']
				if classname in entity_definitions:
					var entity_definition = entity_definitions[classname] as QodotFGDSolidClass
					if entity_definition:
						if entity_definition.spawn_type == QodotFGDSolidClass.SpawnType.MERGE_WORLDSPAWN:
							entity_surface = null

						if not entity_definition.build_visuals:
							entity_surface = null

			if not entity_surface:
				continue

			var mesh: Mesh = null
			if not entity_idx in meshes:
				meshes[entity_idx] = ArrayMesh.new()

			mesh = meshes[entity_idx]
			mesh.add_surface_from_arrays(ArrayMesh.PRIMITIVE_TRIANGLES, entity_surface)
			mesh.surface_set_material(mesh.get_surface_count() - 1, material_dict[texture])

	return meshes

func build_worldspawn_layer_mesh_dict(texture_dict: Dictionary, material_dict: Dictionary, worldspawn_layer_dicts: Array) -> Dictionary:
	var meshes := {}

	for layer in worldspawn_layer_dicts:
		var texture = layer['texture']
		qodot.gather_worldspawn_layer_surfaces(texture, brush_clip_texture, face_skip_texture)
		var texture_surfaces := qodot.fetch_surfaces(inverse_scale_factor) as Array

		var mesh: Mesh = null
		if not texture in meshes:
			meshes[texture] = ArrayMesh.new()

		mesh = meshes[texture]
		mesh.add_surface_from_arrays(ArrayMesh.PRIMITIVE_TRIANGLES, texture_surfaces[0])
		mesh.surface_set_material(mesh.get_surface_count() - 1, material_dict[texture])

	return meshes

func build_entity_mesh_instances(entity_mesh_dict: Dictionary, entity_dicts: Array, entity_definitions: Dictionary, entity_nodes: Array) -> Dictionary:
	var entity_mesh_instances := {}

	for entity_idx in entity_mesh_dict:
		var use_in_baked_light = false

		var entity_dict := entity_dicts[entity_idx] as Dictionary
		var properties = entity_dict['properties']
		var classname = properties['classname']
		if classname in entity_definitions:
			var entity_definition = entity_definitions[classname] as QodotFGDSolidClass
			if entity_definition:
				if entity_definition.spawn_type == QodotFGDSolidClass.SpawnType.WORLDSPAWN:
					use_in_baked_light = true
				elif '_shadow' in properties:
					if properties['_shadow'] == "1":
						use_in_baked_light = true

		var mesh := entity_mesh_dict[entity_idx] as Mesh

		if not mesh:
			continue

		var mesh_instance := MeshInstance.new()
		mesh_instance.name = 'entity_%s_mesh_instance' % entity_idx
		mesh_instance.set_flag(MeshInstance.FLAG_USE_BAKED_LIGHT, use_in_baked_light)

		queue_add_child(entity_nodes[entity_idx], mesh_instance)

		entity_mesh_instances[entity_idx] = mesh_instance

	return entity_mesh_instances

func build_worldspawn_layer_mesh_instances(worldspawn_layers: Array, worldspawn_layer_mesh_dict: Dictionary, worldspawn_layer_nodes: Array) -> Dictionary:
	var worldspawn_layer_mesh_instances := {}

	var idx = 0
	for i in range(0, worldspawn_layers.size()):
		var worldspawn_layer = worldspawn_layers[i]
		var texture_name = worldspawn_layer['texture']
		var mesh := worldspawn_layer_mesh_dict[texture_name] as Mesh

		if not mesh:
			continue

		var mesh_instance := MeshInstance.new()
		mesh_instance.name = 'entity_0_%s_mesh_instance' % worldspawn_layer['name']
		mesh_instance.set_flag(MeshInstance.FLAG_USE_BAKED_LIGHT, true)

		queue_add_child(worldspawn_layer_nodes[idx], mesh_instance)
		idx += 1

		worldspawn_layer_mesh_instances[texture_name] = mesh_instance

	return worldspawn_layer_mesh_instances

func apply_entity_meshes(entity_mesh_dict: Dictionary, entity_mesh_instances: Dictionary) -> void:
	for entity_idx in entity_mesh_dict:
		var mesh := entity_mesh_dict[entity_idx] as Mesh
		var mesh_instance := entity_mesh_instances[entity_idx] as MeshInstance

		if not mesh or not mesh_instance:
			continue

		mesh_instance.set_mesh(mesh)

		queue_add_child(entity_nodes[entity_idx], mesh_instance)

func apply_worldspawn_layer_meshes(worldspawn_layer_mesh_dict: Dictionary, worldspawn_layer_mesh_instances: Dictionary) -> void:
	for texture_name in worldspawn_layer_mesh_dict:
		var mesh = worldspawn_layer_mesh_dict[texture_name]
		var mesh_instance = worldspawn_layer_mesh_instances[texture_name]

		if not mesh or not mesh_instance:
			continue

		mesh_instance.set_mesh(mesh)

func queue_add_child(parent, node, below = null, relative = false) -> void:
	add_child_array.append({"parent": parent, "node": node, "below": below, "relative": relative})

func add_children() -> void:
	while true:
		for i in range(0, set_owner_batch_size):
			var data = add_child_array.pop_front()
			if data:
				add_child_editor(data['parent'], data['node'], data['below'])
				if data['relative']:
					data['node'].global_transform.origin -= data['parent'].global_transform.origin
			else:
				add_children_complete()
				return
		yield(get_tree().create_timer(YIELD_DURATION), YIELD_SIGNAL)

func add_children_complete():
	stop_profile('add_children')

	if should_set_owners:
		start_profile('set_owners')
		set_owners()
	else:
		post_attach()

func set_owners():
	while true:
		for i in range(0, set_owner_batch_size):
			var node = set_owner_array.pop_front()
			if node:
				set_owner_editor(node)
			else:
				set_owners_complete()
				return
		yield(get_tree().create_timer(YIELD_DURATION), YIELD_SIGNAL)

func set_owners_complete():
	stop_profile('set_owners')
	post_attach()

func post_attach():
	run_build_step('build_entity_collision_shapes', [entity_dicts, entity_definitions, entity_collision_shapes])
	yield(get_tree().create_timer(YIELD_DURATION), YIELD_SIGNAL)

	run_build_step('build_worldspawn_layer_collision_shapes', [worldspawn_layers, worldspawn_layer_dicts, worldspawn_layer_collision_shapes])
	yield(get_tree().create_timer(YIELD_DURATION), YIELD_SIGNAL)

	run_build_step('apply_entity_meshes', [entity_mesh_dict, entity_mesh_instances])
	yield(get_tree().create_timer(YIELD_DURATION), YIELD_SIGNAL)

	run_build_step('apply_worldspawn_layer_meshes', [worldspawn_layer_mesh_dict, worldspawn_layer_mesh_instances])
	yield(get_tree().create_timer(YIELD_DURATION), YIELD_SIGNAL)

	run_build_step('apply_properties', [entity_nodes, entity_dicts, entity_definitions])
	yield(get_tree().create_timer(YIELD_DURATION), YIELD_SIGNAL)

	run_build_step('connect_signals', [entity_nodes, entity_dicts, entity_definitions])
	yield(get_tree().create_timer(YIELD_DURATION), YIELD_SIGNAL)

	run_build_step('remove_transient_nodes', [entity_nodes, entity_dicts, entity_definitions])
	yield(get_tree().create_timer(YIELD_DURATION), YIELD_SIGNAL)

	build_complete()

func apply_properties(entity_nodes: Array, entity_dicts: Array, entity_definitions: Dictionary) -> void:
	for entity_idx in range(0, entity_nodes.size()):
		var entity_node = entity_nodes[entity_idx]
		if not entity_node:
			continue

		var entity_dict := entity_dicts[entity_idx] as Dictionary
		var properties := entity_dict['properties'] as Dictionary

		if 'classname' in properties:
			var classname = properties['classname']
			if classname in entity_definitions:
				var entity_definition := entity_definitions[classname] as QodotFGDClass

				for property in properties:
					var prop_string = properties[property]
					if property in entity_definition.class_properties:
						var prop_default = entity_definition.class_properties[property]
						if prop_default is int:
							properties[property] = prop_string.to_int()
						elif prop_default is float:
							properties[property] = prop_string.to_float()
						elif prop_default is Vector3:
							var prop_comps = prop_string.split(" ")
							properties[property] = Vector3(prop_comps[0].to_float(), prop_comps[1].to_float(), prop_comps[2].to_float())
						elif prop_default is Color:
							var prop_comps = prop_string.split(" ")
							var prop_color = Color()

							if "." in prop_comps[0] or "." in prop_comps[1] or "." in prop_comps[2]:
								prop_color.r = prop_comps[0].to_float()
								prop_color.g = prop_comps[1].to_float()
								prop_color.b = prop_comps[2].to_float()
							else:
								prop_color.r8 = prop_comps[0].to_int()
								prop_color.g8 = prop_comps[1].to_int()
								prop_color.b8 = prop_comps[2].to_int()

							properties[property] = prop_color
						elif prop_default is Dictionary:
							properties[property] = prop_string.to_int()
						elif prop_default is Array:
							properties[property] = prop_string.to_int()

		if 'properties' in entity_node:
			entity_node.properties = properties

func connect_signals(entity_nodes: Array, entity_dicts: Array, entity_definitions: Dictionary) -> void:
	for entity_idx in range(0, entity_nodes.size()):
		var entity_node = entity_nodes[entity_idx]
		if not entity_node:
			continue

		var entity_dict := entity_dicts[entity_idx] as Dictionary
		var entity_properties := entity_dict['properties'] as Dictionary

		if not 'target' in entity_properties:
			continue

		var target_nodes := get_nodes_by_targetname(entity_properties['target'])
		for target_node in target_nodes:
			connect_signal(entity_node, target_node)

func connect_signal(entity_node: Node, target_node: Node) -> void:
	if target_node.properties['classname'] == 'signal':
		var signal_name = target_node.properties['signal_name']

		var slot_nodes := get_nodes_by_targetname(target_node.properties['target'])
		for slot_node in slot_nodes:
			if slot_node.properties['classname'] != 'slot':
				continue

			var slot_name = slot_node.properties['slot_name']

			var target_nodes := get_nodes_by_targetname(slot_node.properties['target'])
			for target_node in target_nodes:
				entity_node.connect(signal_name, target_node, slot_name, [], CONNECT_PERSIST)
	else:
		var signal_list = entity_node.get_signal_list()
		for signal_dict in signal_list:
			if signal_dict['name'] == 'trigger':
				entity_node.connect("trigger", target_node, "use", [], CONNECT_PERSIST)
				break

func remove_transient_nodes(entity_nodes: Array, entity_dicts: Array, entity_definitions: Dictionary) -> void:
	for entity_idx in range(0, entity_nodes.size()):
		var entity_node = entity_nodes[entity_idx]
		if not entity_node:
			continue

		var entity_dict := entity_dicts[entity_idx] as Dictionary
		var entity_properties := entity_dict['properties'] as Dictionary

		if not 'classname' in entity_properties:
			continue

		var classname = entity_properties['classname']

		if not classname in entity_definitions:
			continue

		var entity_definition = entity_definitions[classname]
		if entity_definition.transient_node:
			entity_node.get_parent().remove_child(entity_node)
			entity_node.queue_free()


func get_nodes_by_targetname(targetname: String) -> Array:
	var nodes := []

	for node_idx in range(0, entity_nodes.size()):
		var node = entity_nodes[node_idx]
		if not node:
			continue

		var entity_dict := entity_dicts[node_idx] as Dictionary
		var entity_properties := entity_dict['properties'] as Dictionary

		if not 'targetname' in entity_properties:
			continue

		if entity_properties['targetname'] == targetname:
			nodes.append(node)

	return nodes

func build_complete():
	stop_profile('build_map')
	if not print_profiling_data:
		print('\n')
	print('Build complete\n')

	name = cached_name
	cached_name = null

	emit_signal("build_complete", entity_nodes)
