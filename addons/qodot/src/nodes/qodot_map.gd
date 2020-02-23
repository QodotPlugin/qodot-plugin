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
export(bool) var use_trenchbroom_group_hierarchy = true
export(String) var textures := QodotUtil.CATEGORY_STRING
export(String, DIR) var base_texture_dir := "res://textures"
export(String) var texture_file_extension := ".png"
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
var mesh_dict := {}
var entity_nodes := []
var entity_mesh_instances := {}
var entity_physics_bodies := []
var entity_collision_shapes := []

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
	entity_dicts = []
	entity_nodes = []
	entity_mesh_instances = {}
	entity_physics_bodies = []
	entity_collision_shapes = []
	mesh_dict = {}

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

	# Generate geometry
	run_build_step('generate_geometry', [texture_size_dict])
	yield(get_tree().create_timer(YIELD_DURATION), YIELD_SIGNAL)

	# Get entity metadata, populate scene tree
	entity_dicts = run_build_step('fetch_entity_dicts') as Array
	yield(get_tree().create_timer(YIELD_DURATION), YIELD_SIGNAL)

	entity_nodes = run_build_step('build_entity_nodes', [entity_dicts, entity_definitions]) as Array
	yield(get_tree().create_timer(YIELD_DURATION), YIELD_SIGNAL)

	if use_trenchbroom_group_hierarchy and should_add_children:
		run_build_step('resolve_group_hierarchy', [entity_nodes])
		yield(get_tree().create_timer(YIELD_DURATION), YIELD_SIGNAL)

	entity_physics_bodies = run_build_step('build_entity_physics_body_nodes', [entity_dicts, entity_definitions, entity_nodes]) as Array
	yield(get_tree().create_timer(YIELD_DURATION), YIELD_SIGNAL)

	mesh_dict = run_build_step('build_mesh_dict', [texture_dict, material_dict, entity_dicts, entity_definitions]) as Dictionary
	yield(get_tree().create_timer(YIELD_DURATION), YIELD_SIGNAL)

	entity_mesh_instances = run_build_step('build_mesh_instances', [
		mesh_dict,
		entity_dicts,
		entity_definitions,
		entity_nodes,
		entity_physics_bodies
	])
	yield(get_tree().create_timer(YIELD_DURATION), YIELD_SIGNAL)

	entity_collision_shapes = run_build_step('build_entity_collision_shape_nodes', [
		entity_dicts, entity_definitions, entity_physics_bodies
	]) as Array
	yield(get_tree().create_timer(YIELD_DURATION), YIELD_SIGNAL)

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

func generate_geometry(texture_size_dict: Dictionary) -> void:
	qodot.generate_geometry(texture_size_dict);

func fetch_entity_dicts() -> Array:
	return qodot.get_entity_dicts()

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
		var brush_count := entity_dict['brush_count'] as int
		var properties := entity_dict['properties'] as Dictionary

		var node = QodotEntity.new()
		var node_name = "entity_%s" % entity_idx

		if 'classname' in properties:
			var classname = properties['classname']
			node_name += "_" + classname
			if classname in entity_definitions:
				var entity_definition = entity_definitions[classname]
				if entity_definition is QodotFGDSolidClass:
					if entity_definition.spawn_type == QodotFGDSolidClass.SpawnType.MERGE_WORLDSPAWN:
						entity_nodes.append(null)
						continue

					if entity_definition.script_class:
						node.set_script(entity_definition.script_class)
				elif entity_definition is QodotFGDPointClass:
					if entity_definition.scene_file:
						node = entity_definition.scene_file.instance(PackedScene.GEN_EDIT_STATE_INSTANCE)
					elif entity_definition.script_class:
						node.set_script(entity_definition.script_class)

		node.name = node_name

		if 'origin' in properties:
			var origin_comps = properties['origin'].split(' ')
			var origin_vec = Vector3(origin_comps[1].to_float(), origin_comps[2].to_float(), origin_comps[0].to_float())
			node.translation = origin_vec / inverse_scale_factor
		else:
			if entity_idx != 0:
				node.translation = entity_dict['center'] / inverse_scale_factor

		if 'properties' in node:
			node.properties = properties

		entity_nodes.append(node)

		if should_add_children:
			queue_add_child(self, node)

	return entity_nodes

func get_node_properties(node: Node):
	if not node:
		return null

	if not 'properties' in node:
		return null

	return node['properties']

func resolve_group_hierarchy(entity_nodes: Array) -> void:
	var func_groups = []
	var group_entities = []

	# Gather func_groups and their child entities
	for node_idx in range(0, entity_nodes.size()):
		var node = entity_nodes[node_idx]
		var properties = get_node_properties(node)

		if not properties: continue

		if not '_tb_id' in properties and not '_tb_group' in properties:
			continue

		if not 'classname' in properties: continue
		var classname = properties['classname']

		if classname == 'func_group':
			func_groups.append(node)
		else:
			group_entities.append(node)

	# Replace child entity dict reference and ids with func_group's
	for node in group_entities:
		var properties = get_node_properties(node)
		var tb_group = properties['_tb_group']
		var parent = get_node_by_tb_id(tb_group, func_groups)

		if parent:
			node.properties['_tb_id'] = parent.properties['_tb_id']
			if not '_tb_group' in parent.properties:
				node.properties.erase('_tb_group')
			else:
				node.properties['_tb_group'] = parent.properties['_tb_group']

	# Replicate func_group hierarchy with entities
	for node in group_entities:
		var properties = get_node_properties(node)

		if not '_tb_group' in properties:
			continue

		var tb_group = properties['_tb_group']

		for parent in group_entities:
			var parent_properties = get_node_properties(parent)

			var tb_id = parent_properties['_tb_id']

			if tb_id == tb_group:
				queue_add_child(parent, node)

	# Attach func_groups to their respective entities
	for child in func_groups:
		var child_properties = get_node_properties(child)

		var tb_id = child_properties['_tb_id']
		var parent = get_node_by_tb_id(tb_id, group_entities)

		if parent:
			queue_add_child(parent, child)

func get_node_by_tb_id(target_id: String, entity_nodes: Array):
	for node in entity_nodes:
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

func build_entity_physics_body_nodes(entity_dicts: Array, entity_definitions: Dictionary, entity_nodes: Array) -> Array:
	var entity_physics_bodies = []

	for entity_idx in range(0, entity_dicts.size()):
		var entity_dict := entity_dicts[entity_idx] as Dictionary
		var properties = entity_dict['properties']

		var body_class = StaticBody

		if 'classname' in properties:
			var classname = properties['classname']
			if classname in entity_definitions:
				var entity_definition = entity_definitions[classname]

				if entity_definition is QodotFGDSolidClass:
					if entity_definition.spawn_type == QodotFGDSolidClass.SpawnType.MERGE_WORLDSPAWN:
						body_class = null
					else:
						match(entity_definition.physics_body_type):
							QodotFGDSolidClass.PhysicsBodyType.NONE:
								body_class = null
							QodotFGDSolidClass.PhysicsBodyType.AREA:
								body_class = Area
							QodotFGDSolidClass.PhysicsBodyType.STATIC_BODY:
								body_class = StaticBody
							QodotFGDSolidClass.PhysicsBodyType.KINEMATIC_BODY:
								body_class = KinematicBody
							QodotFGDSolidClass.PhysicsBodyType.RIGID_BODY:
								body_class = RigidBody

		var brush_count := entity_dict['brush_count'] as int

		if brush_count == 0 or not body_class:
			entity_physics_bodies.append(null)
			continue

		var node := entity_nodes[entity_idx] as Node
		var physics_body = body_class.new()
		physics_body.name = 'entity_%s_physics_body' % entity_idx
		entity_physics_bodies.append(physics_body)
		queue_add_child(node, physics_body)

	return entity_physics_bodies

func build_entity_collision_shape_nodes(entity_dicts: Array, entity_definitions: Dictionary, entity_physics_bodies: Array) -> Array:
	var entity_collision_shapes_arr := []

	for entity_idx in range(0, entity_physics_bodies.size()):
		var entity_collision_shapes := []

		var entity_dict = entity_dicts[entity_idx]
		var properties = entity_dict['properties']

		var physics_body: CollisionObject = entity_physics_bodies[entity_idx] as CollisionObject
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
						physics_body = entity_physics_bodies[0] as CollisionObject

		if not physics_body:
			entity_collision_shapes_arr.append(null)
			continue

		if concave:
			var collision_shape := CollisionShape.new()
			collision_shape.name = "entity_%s_collision_shape" % entity_idx
			entity_collision_shapes.append(collision_shape)
			queue_add_child(physics_body, collision_shape)
		else:
			for brush_idx in range(0, entity_dict['brush_count']):
				var collision_shape := CollisionShape.new()
				collision_shape.name = "entity_%s_brush_%s_collision_shape" % [entity_idx, brush_idx]
				entity_collision_shapes.append(collision_shape)
				queue_add_child(physics_body, collision_shape)

		entity_collision_shapes_arr.append(entity_collision_shapes)

	return entity_collision_shapes_arr

func build_entity_collision_shapes(entity_dicts: Array, entity_definitions: Dictionary, entity_collision_shapes: Array) -> void:
	for entity_idx in range(0, entity_collision_shapes.size()):
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
			qodot.gather_concave_collision_surfaces(entity_idx)
		else:
			qodot.gather_convex_collision_surfaces(entity_idx)

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

func build_mesh_dict(texture_dict: Dictionary, material_dict: Dictionary, entity_dicts: Array, entity_definitions: Dictionary) -> Dictionary:
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

func build_mesh_instances(mesh_dict: Dictionary, entity_dicts: Array, entity_definitions: Dictionary, entity_nodes: Array, entity_physics_bodies: Array) -> Dictionary:
	var entity_mesh_instances := {}

	for entity_idx in mesh_dict:
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

		var mesh := mesh_dict[entity_idx] as Mesh

		if not mesh:
			continue

		var mesh_instance := MeshInstance.new()
		mesh_instance.name = 'entity_%s_mesh_instance' % entity_idx
		mesh_instance.set_flag(MeshInstance.FLAG_USE_BAKED_LIGHT, use_in_baked_light)

		if not entity_physics_bodies[entity_idx]:
			queue_add_child(entity_nodes[entity_idx], mesh_instance)
		else:
			queue_add_child(entity_physics_bodies[entity_idx], mesh_instance)

		entity_mesh_instances[entity_idx] = mesh_instance

	return entity_mesh_instances

func apply_meshes(mesh_dict: Dictionary, entity_mesh_instances: Dictionary) -> void:
	for entity_idx in mesh_dict:
		var mesh := mesh_dict[entity_idx] as Mesh
		var mesh_instance := entity_mesh_instances[entity_idx] as MeshInstance

		if not mesh or not mesh_instance:
			continue

		mesh_instance.set_mesh(mesh)

		if not entity_physics_bodies[entity_idx]:
			queue_add_child(entity_nodes[entity_idx], mesh_instance)
		else:
			queue_add_child(entity_physics_bodies[entity_idx], mesh_instance)

func queue_add_child(parent, node, below = null) -> void:
	add_child_array.append({"parent": parent, "node": node, "below": below})

func add_children() -> void:
	while true:
		for i in range(0, set_owner_batch_size):
			var data = add_child_array.pop_front()
			if data:
				add_child_editor(data['parent'], data['node'], data['below'])
				if 'properties' in data['node']:
					var properties = data['node']['properties']
					if use_trenchbroom_group_hierarchy and should_add_children:
						if '_tb_id' in properties or '_tb_group' in properties:
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
	run_build_step('apply_meshes', [mesh_dict, entity_mesh_instances])
	yield(get_tree().create_timer(YIELD_DURATION), YIELD_SIGNAL)

	build_complete()

func build_complete():
	stop_profile('build_map')
	if not print_profiling_data:
		print('\n')
	print('Build complete\n')

	name = cached_name
	cached_name = null

	emit_signal("build_complete", entity_nodes)
