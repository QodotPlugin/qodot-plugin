class_name QodotMap
extends QodotSpatial
tool

### Spatial node for rendering a QuakeMap resource into an entity/brush tree

# Pseudo-button for forcing a refresh after asset reimport
export(bool) var reload setget set_reload

# Map file format
export(QodotEnums.MapFormat) var map_format = QodotEnums.MapFormat.STANDARD

# Rendering mode
export(QodotEnums.MapMode) var mode = QodotEnums.MapMode.BRUSH_MESHES

# Factor to scale the .map file's quake units down by
# (16 is a best-effort conversion from Quake 3 units to metric)
export(float) var inverse_scale_factor = 16.0

# .map Resource to auto-load when updating the map from the editor
# (Works around references being held and preventing refresh on reimport)
export(String, FILE, '*.map') var map_file

# Base search path for textures specified in the .map file
export(String, DIR) var base_texture_path = 'res://textures'

# File extensions appended to textures specified in the .map file
export(String) var material_extension = '.tres'
export(String) var texture_extension = '.png'

# Materials
export (SpatialMaterial) var default_material

# Mappers used to control tree population
export(Script) var entity_mapper = QodotEntityMapper
export(Script) var brush_mapper = QodotBrushMapper
export(Script) var face_mapper = QodotFaceMapper

# Threads
export(int) var max_build_threads = 4
export(int) var build_bucket_size = 4

# Instances
var map_reader = null
var texture_mapper = QodotTextureMapper.new()

var build_thread = Thread.new()

var build_start_timestamp = 0

## Setters
func set_reload(new_reload):
	if reload != new_reload:
		if Engine.is_editor_hint():
			if build_thread.is_active():
				print("Skipping reload: Build in progress")
				return

			clear_map()

			if not map_file:
				print("Skipping reload: No map file")
				return

			build_thread.start(self, "build_map")

# Returns whether a given format uses Valve-style UVs
func get_valve_uvs(map_format: int):
	return map_format == QodotEnums.MapFormat.VALVE

# Returns the bimask format for a given map format
func get_bitmask_format(map_format: int):
	match map_format:
		QodotEnums.MapFormat.QUAKE_2:
			return QodotEnums.BitmaskFormat.QUAKE_2
		QodotEnums.MapFormat.QUAKE_3:
			return QodotEnums.BitmaskFormat.QUAKE_2
		QodotEnums.MapFormat.QUAKE_3_LEGACY:
			return QodotEnums.BitmaskFormat.QUAKE_2
		QodotEnums.MapFormat.HEXEN_2:
			return QodotEnums.BitmaskFormat.HEXEN_2
		QodotEnums.MapFormat.DAIKATANA:
			return QodotEnums.BitmaskFormat.DAIKATANA

	return QodotEnums.BitmaskFormat.NONE

func _exit_tree():
	build_thread.wait_to_finish()

# Clears any existing children
func clear_map():
	for child in get_children():
		if(child.get_script() == QodotEntity):
			remove_child(child)
			child.queue_free()

# Kicks off the map building process
func build_map(userdata):
	var entity_node_dict = {}
	var brush_node_dict = {}
	var brush_collision_dict = {}
	var brush_visuals_dict = {}

	build_start_timestamp = OS.get_ticks_msec()

	var thread_pool = QodotThreadPool.new()
	thread_pool.set_max_threads(max_build_threads)
	thread_pool.set_bucket_size(build_bucket_size)

	print("Building map...")

	if not map_reader:
		map_reader = QuakeMapReader.new()

	map_reader.open_map(map_file)
	var worldspawn_properties = map_reader.read_entity_properties(0)
	var entity_count = map_reader.get_entity_count()
	var brush_count = map_reader.get_brush_count()

	if 'message' in worldspawn_properties:
		call_deferred("set_name", worldspawn_properties['message'])

	print("\nWorldspawn Properties:")
	for property in worldspawn_properties:
		print("\t", property, ": ", worldspawn_properties[property])

	print("\nEntity Count: ", entity_count)
	print("Brush Count: ", brush_count, "\n")

	for entity_idx in range(0, entity_count):
		thread_pool.add_thread_job(self, "build_entity", entity_idx)

	print("Queued ", entity_count, " entities for building.")

	print("Building entities...")
	thread_pool.start_thread_jobs()
	var entity_results = yield(thread_pool, "jobs_complete")
	print("Entities complete.\n")

	for result_idx in entity_results:
		var result = entity_results[result_idx]
		var entity_idx = result[0]
		var entity_node = result[1]
		entity_node_dict[entity_idx] = entity_node
		brush_node_dict[entity_idx] = {}
		brush_collision_dict[entity_idx] = {}
		brush_visuals_dict[entity_idx] = {}

	var queued_brushes = 0
	for entity_idx in entity_node_dict:
		for brush_idx in range(0, map_reader.get_entity_brush_count(entity_idx)):
			thread_pool.add_thread_job(self, "build_brush", [entity_idx, brush_idx])
			queued_brushes += 1

	print("Queued ", queued_brushes, " brushes for building.")

	print("Building brushes...")
	thread_pool.start_thread_jobs()
	var brush_results = yield(thread_pool, "jobs_complete")
	print("Brushes complete.\n")

	for result_idx in brush_results:
		var result = brush_results[result_idx]
		var entity_idx = result[0]
		var brush_idx = result[1]
		var brush_node = result[2]
		brush_node_dict[entity_idx][brush_idx] = brush_node

	queued_brushes = 0
	for entity_idx in entity_node_dict:
		var entity_properties = map_reader.read_entity_properties(entity_idx)
		for brush_idx in brush_node_dict[entity_idx]:
			var brush = map_reader.read_entity_brush(entity_idx, brush_idx, get_valve_uvs(map_format), get_bitmask_format(map_format))
			if brush_mapper.should_spawn_brush_collision(entity_properties, brush):
				thread_pool.add_thread_job(self, "build_brush_collision", [entity_idx, brush_idx])
				queued_brushes += 1

	print("Queued ", queued_brushes, " brushes for collision building.")

	print("Building collision...")
	thread_pool.start_thread_jobs()
	var collision_results = yield(thread_pool, "jobs_complete")
	print("Collision build complete.\n")

	for result_idx in collision_results:
		var result = collision_results[result_idx]
		var entity_idx = result[0]
		var brush_idx = result[1]
		var brush_node = result[2]
		brush_collision_dict[entity_idx][brush_idx] = brush_node

	queued_brushes = 0
	for entity_idx in entity_node_dict:
		var entity_node = entity_node_dict[entity_idx]
		var entity_properties = map_reader.read_entity_properties(entity_idx)
		for brush_idx in brush_node_dict[entity_idx]:
			var brush_node = brush_node_dict[entity_idx][brush_idx]
			var brush = map_reader.read_entity_brush(entity_idx, brush_idx, get_valve_uvs(map_format), get_bitmask_format(map_format))
			if brush_mapper.should_spawn_brush_mesh(entity_properties, brush):
				thread_pool.add_thread_job(self, "build_brush_visuals", [entity_idx, brush_idx])
				queued_brushes += 1

	print("Queued ", queued_brushes, " brushes for visual building.")

	print("Building visuals...")
	thread_pool.start_thread_jobs()
	var visuals_results = yield(thread_pool, "jobs_complete")
	print("Visual build complete.\n")

	for result_idx in visuals_results:
		var result = visuals_results[result_idx]
		var entity_idx = result[0]
		var brush_idx = result[1]
		var brush_node = result[2]
		brush_visuals_dict[entity_idx][brush_idx] = brush_node

	thread_pool.finish()

	call_deferred("build_complete", [entity_node_dict, brush_node_dict, brush_collision_dict, brush_visuals_dict])

func build_complete(dicts):
	print("Adding nodes to editor tree...")

	build_thread.wait_to_finish()

	var entity_node_dict = dicts[0]
	var brush_node_dict = dicts[1]
	var brush_collision_dict = dicts[2]
	var brush_visuals_dict = dicts[3]

	var entity_keys = entity_node_dict.keys()
	entity_keys.sort()

	for entity_idx in entity_keys:
		var entity_node = entity_node_dict[entity_idx]

		var brush_keys = brush_node_dict[entity_idx].keys()
		brush_keys.sort()

		for brush_idx in brush_keys:
			var brush_node = brush_node_dict[entity_idx][brush_idx]

			if brush_idx in brush_collision_dict[entity_idx]:
				for collision_object in brush_collision_dict[entity_idx][brush_idx]:
					brush_node.add_child(collision_object)

			if brush_idx in brush_visuals_dict[entity_idx]:
				for visual_object in brush_visuals_dict[entity_idx][brush_idx]:
					brush_node.add_child(visual_object)

			entity_node.add_child(brush_node)

		add_child(entity_node)

	var edited_scene_root = get_tree().get_edited_scene_root()
	add_children_to_editor(edited_scene_root)

	print("Cleaning up...")
	map_reader.call_deferred("close_map")

	var build_end_timestamp = OS.get_ticks_msec()
	var build_duration = build_end_timestamp - build_start_timestamp
	print("Build complete after ", build_duration * 0.001, " seconds.")

# Creates a node representation of an entity and its child brushes
func build_entity(entity_idx):
	var entity_properties = map_reader.read_entity_properties(entity_idx)

	if entity_mapper != null:
		var entity_node = entity_mapper.spawn_entity(entity_properties, inverse_scale_factor)

		var entity_spawned_node = entity_mapper.spawn_node_for_entity(entity_properties)
		if(entity_spawned_node != null):
			entity_node.add_child(entity_spawned_node)

		return [entity_idx, entity_node]

# Creates a node representation of a brush
func build_brush(userdata):
	var entity_idx = userdata[0]
	var brush_idx = userdata[1]

	var brush = map_reader.read_entity_brush(entity_idx, brush_idx, get_valve_uvs(map_format), get_bitmask_format(map_format))

	var brush_node = QodotBrush.new()
	brush_node.name = 'Brush0'
	brush_node.translation = brush.center / inverse_scale_factor

	return [entity_idx, brush_idx, brush_node]

func build_brush_collision(userdata):
	var entity_idx = userdata[0]
	var brush_idx = userdata[1]

	var entity_properties = map_reader.read_entity_properties(entity_idx)
	var brush = map_reader.read_entity_brush(entity_idx, brush_idx, get_valve_uvs(map_format), get_bitmask_format(map_format))
	var brush_collision_objects = brush_mapper.create_brush_collision_objects(entity_properties, brush, inverse_scale_factor)

	return [entity_idx, brush_idx, brush_collision_objects]

func build_brush_visuals(userdata):
	var entity_idx = userdata[0]
	var brush_idx = userdata[1]

	var entity_properties = map_reader.read_entity_properties(entity_idx)
	var brush = map_reader.read_entity_brush(entity_idx, brush_idx, get_valve_uvs(map_format), get_bitmask_format(map_format))

	var brush_visuals = []

	match mode:
		QodotEnums.MapMode.FACE_AXES:
			brush_visuals = brush_mapper.create_brush_face_axes(brush, inverse_scale_factor)

		QodotEnums.MapMode.FACE_VERTICES:
			brush_visuals = brush_mapper.create_brush_face_vertices(brush, inverse_scale_factor)

		QodotEnums.MapMode.BRUSH_MESHES:
			var face_meshes = brush_mapper.create_brush_meshes(entity_properties, brush, face_mapper, texture_mapper, base_texture_path, material_extension, texture_extension, default_material, inverse_scale_factor)
			for face_mesh in face_meshes:
				brush_visuals.append(face_mesh)

	return [entity_idx, brush_idx, brush_visuals]

func add_children_to_editor(edited_scene_root):
	for child in get_children():
		recursive_set_owner(child, edited_scene_root)

func recursive_set_owner(node, new_owner):
	node.set_owner(new_owner)
	for child in node.get_children():
		self.recursive_set_owner(child, new_owner)
