class_name QodotMap
extends QodotSpatial
tool

const DEBUG := false
const YIELD_DURATION := 0.0
const YIELD_SIGNAL := "timeout"

signal build_complete()
signal build_progress(step, progress)
signal build_failed()

signal unwrap_uv2_complete()

var map_file := "" setget set_map_file
var inverse_scale_factor := 16.0
var entity_fgd := preload("res://addons/qodot/game_definitions/fgd/qodot_fgd.tres")
var base_texture_dir := "res://textures"
var texture_file_extensions := PoolStringArray(["png"])

var worldspawn_layers := [] setget set_worldspawn_layers

var brush_clip_texture := "special/clip"
var face_skip_texture := "special/skip"
var texture_wads := [] setget set_texture_wads
var material_file_extension := "tres"
var default_material := SpatialMaterial.new()
var uv_unwrap_texel_size := 1.0
var print_profiling_data := false
var use_trenchbroom_group_hierarchy := false
var tree_attach_batch_size := 16
var set_owner_batch_size := 16

# Build context variables
var qodot = null

var profile_timestamps := {}

var add_child_array := []
var set_owner_array := []

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

func set_map_file(new_map_file: String) -> void:
	if map_file != new_map_file:
		map_file = new_map_file

func set_worldspawn_layers(new_worldspawn_layers: Array) -> void:
	if worldspawn_layers != new_worldspawn_layers:
		worldspawn_layers = new_worldspawn_layers

		for i in range(0, worldspawn_layers.size()):
			if not worldspawn_layers[i]:
				worldspawn_layers[i] = QodotWorldspawnLayer.new()

func set_texture_wads(new_texture_wads: Array) -> void:
	if texture_wads != new_texture_wads:
		texture_wads = new_texture_wads

		for i in range(0, texture_wads.size()):
			var texture_wad = texture_wads[i]
			if not texture_wad:
				texture_wads[i] = Object()

# Overrides
func _ready() -> void:
	if not DEBUG:
		return

	if not Engine.is_editor_hint():
		if verify_parameters():
			build_map()

func _get_property_list() -> Array:
	return [
		QodotUtil.category_dict('Map'),
		QodotUtil.property_dict('map_file', TYPE_STRING, PROPERTY_HINT_GLOBAL_FILE, '*.map'),
		QodotUtil.property_dict('inverse_scale_factor', TYPE_INT),
		QodotUtil.category_dict('Entities'),
		QodotUtil.property_dict('entity_fgd', TYPE_OBJECT, PROPERTY_HINT_RESOURCE_TYPE, 'Resource'),
		QodotUtil.category_dict('Textures'),
		QodotUtil.property_dict('base_texture_dir', TYPE_STRING, PROPERTY_HINT_DIR),
		QodotUtil.property_dict('texture_file_extensions', TYPE_STRING_ARRAY),
		QodotUtil.property_dict('worldspawn_layers', TYPE_ARRAY),
		QodotUtil.property_dict('brush_clip_texture', TYPE_STRING),
		QodotUtil.property_dict('face_skip_texture', TYPE_STRING),
		QodotUtil.property_dict('texture_wads', TYPE_ARRAY, -1),
		QodotUtil.category_dict('Materials'),
		QodotUtil.property_dict('material_file_extension', TYPE_STRING),
		QodotUtil.property_dict('default_material', TYPE_OBJECT, PROPERTY_HINT_RESOURCE_TYPE, 'SpatialMaterial'),
		QodotUtil.category_dict('UV Unwrap'),
		QodotUtil.property_dict('uv_unwrap_texel_size', TYPE_REAL),
		QodotUtil.category_dict('Build'),
		QodotUtil.property_dict('print_profiling_data', TYPE_BOOL),
		QodotUtil.property_dict('use_trenchbroom_group_hierarchy', TYPE_BOOL),
		QodotUtil.property_dict('tree_attach_batch_size', TYPE_INT),
		QodotUtil.property_dict('set_owner_batch_size', TYPE_INT)
	]

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
	if not qodot or DEBUG:
		var qodot_lib = GDNativeLibrary.new()
		qodot_lib.set("entry/OSX.64", "res://addons/qodot/bin/osx/libqodot.dylib")
		qodot_lib.set("entry/Windows.64", "res://addons/qodot/bin/win64/libqodot.dll")
		qodot_lib.set("entry/X11.64", "res://addons/qodot/bin/x11/libqodot.so")
		qodot_lib.set("dependency/OSX.64", ["res://addons/qodot/bin/osx/libmap.dylib"])
		qodot_lib.set("dependency/Windows.64", ["res://addons/qodot/bin/win64/libmap.dll"])
		qodot_lib.set("dependency/X11.64", ["res://addons/qodot/bin/x11/libmap.so"])

		var qodot_script = NativeScript.new()
		qodot_script.set("class_name", "Qodot")
		qodot_script.library = qodot_lib

		qodot = qodot_script.new()

	if not qodot:
		push_error("Error: Failed to load libqodot.")
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
	add_child_array = []
	set_owner_array = []

	texture_list = []
	texture_loader = null
	texture_dict = {}
	texture_size_dict = {}
	material_dict = {}
	entity_definitions = {}
	entity_dicts = []
	worldspawn_layer_dicts = []
	entity_mesh_dict = {}
	worldspawn_layer_mesh_dict = {}
	entity_nodes = []
	worldspawn_layer_nodes = []
	entity_mesh_instances = {}
	worldspawn_layer_mesh_instances = {}
	entity_collision_shapes = []
	worldspawn_layer_collision_shapes = []

	build_step_index = 0
	build_step_count = 0

func start_profile(item_name: String) -> void:
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
	var result = callv(step_name, params)
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

var build_step_index := 0
var build_step_count := 0
var build_steps := []
var post_attach_steps := []

func register_build_step(build_step: String, arguments := [], target := "", post_attach := false) -> void:
	(post_attach_steps if post_attach else build_steps).append([build_step, arguments, target])
	build_step_count += 1

func run_build_steps(post_attach := false) -> void:
	var target_array = post_attach_steps if post_attach else build_steps

	while target_array.size() > 0:
		var build_step = target_array.pop_front()
		var result = run_build_step(build_step[0], build_step[1])
		var target = build_step[2]
		if target != "":
			set(target, result)

		emit_signal("build_progress", build_step[0], float(build_step_index + 1) / float(build_step_count))
		build_step_index += 1

		yield(get_tree().create_timer(YIELD_DURATION), YIELD_SIGNAL)

	if post_attach:
		build_complete()
	else:
		start_profile('add_children')
		add_children()

func register_build_steps() -> void:
	register_build_step('remove_children')
	register_build_step('load_map')
	register_build_step('fetch_texture_list', [], 'texture_list')
	register_build_step('init_texture_loader', [], 'texture_loader')
	register_build_step('load_textures', [], 'texture_dict')
	register_build_step('build_texture_size_dict', [], 'texture_size_dict')
	register_build_step('build_materials', [], 'material_dict')
	register_build_step('fetch_entity_definitions', [], 'entity_definitions')
	register_build_step('set_qodot_entity_definitions', [])
	register_build_step('set_qodot_worldspawn_layers', [])
	register_build_step('generate_geometry', [])
	register_build_step('fetch_entity_dicts', [], 'entity_dicts')
	register_build_step('fetch_worldspawn_layer_dicts', [], 'worldspawn_layer_dicts')
	register_build_step('build_entity_nodes', [], 'entity_nodes')
	register_build_step('build_worldspawn_layer_nodes', [], 'worldspawn_layer_nodes')
	register_build_step('resolve_group_hierarchy', [])
	register_build_step('build_entity_mesh_dict', [], 'entity_mesh_dict')
	register_build_step('build_worldspawn_layer_mesh_dict', [], 'worldspawn_layer_mesh_dict')
	register_build_step('build_entity_mesh_instances', [], 'entity_mesh_instances')
	register_build_step('build_worldspawn_layer_mesh_instances', [], 'worldspawn_layer_mesh_instances')
	register_build_step('build_entity_collision_shape_nodes', [], 'entity_collision_shapes')
	register_build_step('build_worldspawn_layer_collision_shape_nodes', [], 'worldspawn_layer_collision_shapes')

func register_post_attach_steps() -> void:
	register_build_step('build_entity_collision_shapes', [], "", true)
	register_build_step('build_worldspawn_layer_collision_shapes', [], "", true)
	register_build_step('apply_entity_meshes', [], "", true)
	register_build_step('apply_worldspawn_layer_meshes', [], "", true)
	register_build_step('apply_properties', [], "", true)
	register_build_step('connect_signals', [], "", true)
	register_build_step('remove_transient_nodes', [], "", true)

# Actions
func build_map() -> void:
	reset_build_context()

	print('Building %s\n' % map_file)
	start_profile('build_map')

	register_build_steps()
	register_post_attach_steps()

	run_build_steps()

func unwrap_uv2(node: Node = null) -> void:
	var target_node = null

	if node:
		target_node = node
	else:
		target_node = self
		print("Unwrapping mesh UV2s")

	if target_node is MeshInstance:
		var mesh = target_node.get_mesh()
		if mesh is ArrayMesh:
			mesh.lightmap_unwrap(Transform.IDENTITY, uv_unwrap_texel_size / inverse_scale_factor)

	for child in target_node.get_children():
		unwrap_uv2(child)

	if not node:
		print("Unwrap complete")
		emit_signal("unwrap_uv2_complete")

# Build Steps

func remove_children() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

func load_map() -> void:
	var file: String = map_file
	qodot.load_map(file)

func fetch_texture_list() -> Array:
	return qodot.get_texture_list() as Array

func init_texture_loader() -> QodotTextureLoader:
	return QodotTextureLoader.new(
		base_texture_dir,
		texture_file_extensions,
		texture_wads
	)

func load_textures() -> Dictionary:
	return texture_loader.load_textures(texture_list) as Dictionary

func build_materials() -> Dictionary:
	return texture_loader.create_materials(texture_list, material_file_extension, default_material)

func fetch_entity_definitions() -> Dictionary:
	return entity_fgd.get_entity_definitions()

func set_qodot_entity_definitions() -> void:
	qodot.set_entity_definitions(build_libmap_entity_definitions(entity_definitions))

func set_qodot_worldspawn_layers() -> void:
	qodot.set_worldspawn_layers(build_libmap_worldspawn_layers(worldspawn_layers))

func generate_geometry() -> void:
	qodot.generate_geometry(texture_size_dict);

func fetch_entity_dicts() -> Array:
	return qodot.get_entity_dicts()

func fetch_worldspawn_layer_dicts() -> Array:
	var layer_dicts = qodot.get_worldspawn_layer_dicts()
	return layer_dicts if layer_dicts else []

func build_texture_size_dict() -> Dictionary:
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

func build_libmap_worldspawn_layers(worldspawn_layers: Array) -> Array:
	var libmap_worldspawn_layers := []
	for worldspawn_layer in worldspawn_layers:
		libmap_worldspawn_layers.append({
			'name': worldspawn_layer.name,
			'texture': worldspawn_layer.texture,
			'node_class': worldspawn_layer.node_class,
			'build_visuals': worldspawn_layer.build_visuals,
			'collision_shape_type': worldspawn_layer.collision_shape_type,
			'script_class': worldspawn_layer.script_class
		})
	return libmap_worldspawn_layers

func build_entity_nodes() -> Array:
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
					elif use_trenchbroom_group_hierarchy and entity_definition.spawn_type == QodotFGDSolidClass.SpawnType.GROUP:
						should_add_child = false
					if entity_definition.node_class != "":
						node = ClassDB.instance(entity_definition.node_class)
				elif entity_definition is QodotFGDPointClass:
					if entity_definition.scene_file:
						var flag = PackedScene.GEN_EDIT_STATE_DISABLED
						if Engine.is_editor_hint():
							flag = PackedScene.GEN_EDIT_STATE_INSTANCE
						node = entity_definition.scene_file.instance(flag)

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

func build_worldspawn_layer_nodes() -> Array:
	var worldspawn_layer_nodes := []

	for worldspawn_layer in worldspawn_layers:
		var node = ClassDB.instance(worldspawn_layer.node_class)
		node.name = "entity_0_" + worldspawn_layer.name
		if worldspawn_layer.script_class:
			node.set_script(worldspawn_layer.script_class)

		worldspawn_layer_nodes.append(node)
		queue_add_child(self, node, entity_nodes[0])

	return worldspawn_layer_nodes

func resolve_group_hierarchy() -> void:
	if not use_trenchbroom_group_hierarchy:
		return

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

func build_entity_collision_shape_nodes() -> Array:
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

func build_worldspawn_layer_collision_shape_nodes() -> Array:
	var worldspawn_layer_collision_shapes := []

	for layer_idx in range(0, worldspawn_layers.size()):
		if layer_idx >= worldspawn_layer_dicts.size():
			continue

		var layer = worldspawn_layers[layer_idx]

		var layer_dict = worldspawn_layer_dicts[layer_idx]
		var node := worldspawn_layer_nodes[layer_idx] as Node
		var concave = false

		var shapes := []

		if layer.collision_shape_type == QodotFGDSolidClass.CollisionShapeType.NONE:
			worldspawn_layer_collision_shapes.append(shapes)
			continue
		elif layer.collision_shape_type == QodotFGDSolidClass.CollisionShapeType.CONCAVE:
			concave = true

		if not node:
			worldspawn_layer_collision_shapes.append(shapes)
			continue

		if concave:
			var collision_shape := CollisionShape.new()
			collision_shape.name = "entity_0_%s_collision_shape" % layer.name
			shapes.append(collision_shape)
			queue_add_child(node, collision_shape)
		else:
			for brush_idx in layer_dict['brush_indices']:
				var collision_shape := CollisionShape.new()
				collision_shape.name = "entity_0_%s_brush_%s_collision_shape" % [layer.name, brush_idx]
				shapes.append(collision_shape)
				queue_add_child(node, collision_shape)

		worldspawn_layer_collision_shapes.append(shapes)

	return worldspawn_layer_collision_shapes

func build_entity_collision_shapes() -> void:
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

func build_worldspawn_layer_collision_shapes() -> void:
	for layer_idx in range(0, worldspawn_layers.size()):
		if layer_idx >= worldspawn_layer_dicts.size():
			continue

		var layer = worldspawn_layers[layer_idx]
		var concave = false

		match(layer.collision_shape_type):
			QodotFGDSolidClass.CollisionShapeType.NONE:
				continue
			QodotFGDSolidClass.CollisionShapeType.CONVEX:
				concave = false
			QodotFGDSolidClass.CollisionShapeType.CONCAVE:
				concave = true

		var layer_dict = worldspawn_layer_dicts[layer_idx]

		if not worldspawn_layer_collision_shapes[layer_idx]:
			continue

		qodot.gather_worldspawn_layer_collision_surfaces(0)

		var layer_surfaces := qodot.fetch_surfaces(inverse_scale_factor) as Array

		var verts := PoolVector3Array()

		for i in range(0, layer_dict.brush_indices.size()):
			var surface_idx = layer_dict.brush_indices[i]
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

				var collision_shape = worldspawn_layer_collision_shapes[layer_idx][i]
				collision_shape.set_shape(shape)

		if concave:
			if verts.size() == 0:
				continue

			var shape = ConcavePolygonShape.new()
			shape.set_faces(verts)

			var collision_shape = worldspawn_layer_collision_shapes[layer_idx][0]
			collision_shape.set_shape(shape)

func build_entity_mesh_dict() -> Dictionary:
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

func build_worldspawn_layer_mesh_dict() -> Dictionary:
	var meshes := {}

	for layer in worldspawn_layer_dicts:
		var texture = layer.texture
		qodot.gather_worldspawn_layer_surfaces(texture, brush_clip_texture, face_skip_texture)
		var texture_surfaces := qodot.fetch_surfaces(inverse_scale_factor) as Array

		var mesh: Mesh = null
		if not texture in meshes:
			meshes[texture] = ArrayMesh.new()

		mesh = meshes[texture]
		mesh.add_surface_from_arrays(ArrayMesh.PRIMITIVE_TRIANGLES, texture_surfaces[0])
		mesh.surface_set_material(mesh.get_surface_count() - 1, material_dict[texture])

	return meshes

func build_entity_mesh_instances() -> Dictionary:
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

func build_worldspawn_layer_mesh_instances() -> Dictionary:
	var worldspawn_layer_mesh_instances := {}

	var idx = 0
	for i in range(0, worldspawn_layers.size()):
		var worldspawn_layer = worldspawn_layers[i]
		var texture_name = worldspawn_layer.texture

		if not texture_name in worldspawn_layer_mesh_dict:
			continue

		var mesh := worldspawn_layer_mesh_dict[texture_name] as Mesh

		if not mesh:
			continue

		var mesh_instance := MeshInstance.new()
		mesh_instance.name = 'entity_0_%s_mesh_instance' % worldspawn_layer.name
		mesh_instance.set_flag(MeshInstance.FLAG_USE_BAKED_LIGHT, true)

		queue_add_child(worldspawn_layer_nodes[idx], mesh_instance)
		idx += 1

		worldspawn_layer_mesh_instances[texture_name] = mesh_instance

	return worldspawn_layer_mesh_instances

func apply_entity_meshes() -> void:
	for entity_idx in entity_mesh_dict:
		var mesh := entity_mesh_dict[entity_idx] as Mesh
		var mesh_instance := entity_mesh_instances[entity_idx] as MeshInstance

		if not mesh or not mesh_instance:
			continue

		mesh_instance.set_mesh(mesh)

		queue_add_child(entity_nodes[entity_idx], mesh_instance)

func apply_worldspawn_layer_meshes() -> void:
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
		run_build_steps(true)

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
	run_build_steps(true)

func apply_properties() -> void:
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

func connect_signals() -> void:
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

		var receiver_nodes := get_nodes_by_targetname(target_node.properties['target'])
		for receiver_node in receiver_nodes:
			if receiver_node.properties['classname'] != 'receiver':
				continue

			var receiver_name = receiver_node.properties['receiver_name']

			var target_nodes := get_nodes_by_targetname(receiver_node.properties['target'])
			for target_node in target_nodes:
				entity_node.connect(signal_name, target_node, receiver_name, [], CONNECT_PERSIST)
	else:
		var signal_list = entity_node.get_signal_list()
		for signal_dict in signal_list:
			if signal_dict['name'] == 'trigger':
				entity_node.connect("trigger", target_node, "use", [], CONNECT_PERSIST)
				break

func remove_transient_nodes() -> void:
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

	emit_signal("build_complete")
