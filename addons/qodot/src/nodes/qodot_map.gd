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
export(int) var max_build_threads = 4 setget set_max_build_threads
export(int) var build_bucket_size = 4 setget set_build_bucket_size

# Instances
var map_reader = null
var thread_pool = QodotThreadPool.new()
var texture_mapper = QodotTextureMapper.new()

var build_start_timestamp = 0

## Setters
func set_reload(new_reload):
	if reload != new_reload:
		if Engine.is_editor_hint():
			if thread_pool.jobs_running() > 0 || thread_pool.jobs_pending() > 0:
				print("Skipping reload: Build in progress")
				return

			clear_map()

			if not map_file:
				print("Skipping reload: No map file")
				return

			build_map()

func set_max_build_threads(new_max_build_threads):
	if max_build_threads != new_max_build_threads:
		max_build_threads = new_max_build_threads
		thread_pool.set_max_threads(max_build_threads)

func set_build_bucket_size(new_build_bucket_size):
	if build_bucket_size != new_build_bucket_size:
		build_bucket_size = new_build_bucket_size
		thread_pool.set_bucket_size(build_bucket_size)

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

# Clears any existing children
func clear_map():
	for child in get_children():
		remove_child(child)
		child.queue_free()

# Kicks off the map building process
func build_map():
	build_start_timestamp = OS.get_ticks_msec()

	print("Building map...")

	if not map_reader:
		map_reader = QuakeMapReader.new()

	map_reader.open_map(map_file)
	var worldspawn_properties = map_reader.read_entity_properties(0)
	print("read worldspawn: ", worldspawn_properties)
	var entity_count = map_reader.get_entity_count()
	print("read entity count: ", entity_count)

	if 'message' in worldspawn_properties:
		name = worldspawn_properties['message']

	for entity_idx in range(0, entity_count):
		thread_pool.add_thread_job(self, "build_entity", [self, entity_idx])

	print("Queued ", entity_count, " entities for building.")

	if not thread_pool.is_connected("jobs_complete", self, "entities_complete"):
		thread_pool.connect("jobs_complete", self, "entities_complete")

	print("Building entities...")
	thread_pool.start_thread_jobs()

# Creates a node representation of an entity and its child brushes
func build_entity(userdata):
	var parent_node = userdata[0]
	var entity_idx = userdata[1]

	var entity_properties = map_reader.read_entity_properties(entity_idx)

	if entity_mapper != null:
		var entity_node = entity_mapper.spawn_entity(entity_properties, inverse_scale_factor)

		var entity_spawned_node = entity_mapper.spawn_node_for_entity(entity_properties)
		if(entity_spawned_node != null):
			entity_node.add_child(entity_spawned_node)

		parent_node.call_deferred("add_child", entity_node)

# Build completion event, recursively adds child nodes to the editor tree
func entities_complete():
	thread_pool.disconnect("jobs_complete", self, "entities_complete")

	print("Entities complete.")

	var queued_brushes = 0
	for entity_idx in range(0, get_child_count()):
		var entity_node = get_child(entity_idx)
		var brush_count = map_reader.get_entity_brush_count(entity_idx)
		for brush_idx in range(0, brush_count):
			thread_pool.add_thread_job(self, "build_brush", [entity_node, entity_idx, brush_idx])
			queued_brushes += 1

	print("Queued ", queued_brushes, " brushes for building.")

	if not thread_pool.is_connected("jobs_complete", self, "brushes_complete"):
		thread_pool.connect("jobs_complete", self, "brushes_complete")

	print("Building brushes...")
	thread_pool.start_thread_jobs()

# Creates a node representation of a brush
func build_brush(userdata):
	var entity_node = userdata[0]
	var entity_idx = userdata[1]
	var brush_idx = userdata[2]

	var brush = map_reader.read_entity_brush(entity_idx, brush_idx, get_valve_uvs(map_format), get_bitmask_format(map_format))

	var brush_node = QodotBrush.new()
	brush_node.name = 'Brush0'
	brush_node.translation = brush.center / inverse_scale_factor

	entity_node.call_deferred("add_child", brush_node)

func brushes_complete():
	thread_pool.disconnect("jobs_complete", self, "brushes_complete")

	print("Brushes complete.")

	var queued_brushes = 0
	for entity_idx in range(0, get_child_count()):
		var entity_node = get_child(entity_idx)
		var entity_properties = map_reader.read_entity_properties(entity_idx)
		var brush_idx = 0
		for child_idx in range(0, entity_node.get_child_count()):
			var child_node = entity_node.get_child(child_idx)
			if child_node.get_script() == QodotBrush:
				var brush = map_reader.read_entity_brush(entity_idx, brush_idx, get_valve_uvs(map_format), get_bitmask_format(map_format))
				if brush_mapper.should_spawn_brush_collision(entity_properties, brush):
					thread_pool.add_thread_job(self, "build_brush_collision", [child_node, entity_idx, brush_idx])
					queued_brushes += 1
				brush_idx += 1

	print("Queued ", queued_brushes, " brushes for collision building.")

	if not thread_pool.is_connected("jobs_complete", self, "brush_collision_complete"):
		thread_pool.connect("jobs_complete", self, "brush_collision_complete")

	print("Building collision...")
	thread_pool.start_thread_jobs()

func build_brush_collision(userdata):
	var brush_node = userdata[0]
	var entity_idx = userdata[1]
	var brush_idx = userdata[2]

	var entity_properties = map_reader.read_entity_properties(entity_idx)
	var brush = map_reader.read_entity_brush(entity_idx, brush_idx, get_valve_uvs(map_format), get_bitmask_format(map_format))

	var brush_collision_objects = brush_mapper.create_brush_collision_objects(entity_properties, brush, inverse_scale_factor)

	for collision_object in brush_collision_objects:
		brush_node.call_deferred("add_child", collision_object)

func brush_collision_complete():
	thread_pool.disconnect("jobs_complete", self, "brush_collision_complete")

	print("Collision build complete.")

	var queued_brushes = 0
	for entity_idx in range(0, get_child_count()):
		var entity_properties = map_reader.read_entity_properties(entity_idx)
		var entity_node = get_child(entity_idx)
		var brush_idx = 0
		for child_idx in range(0, entity_node.get_child_count()):
			var child_node = entity_node.get_child(child_idx)
			if child_node.get_script() == QodotBrush:
				var brush = map_reader.read_entity_brush(entity_idx, brush_idx, get_valve_uvs(map_format), get_bitmask_format(map_format))
				if brush_mapper.should_spawn_brush_mesh(entity_properties, brush):
					thread_pool.add_thread_job(self, "build_brush_visuals", [child_node, entity_idx, brush_idx])
					queued_brushes += 1
				brush_idx += 1

	print("Queued ", queued_brushes, " brushes for visual building.")

	if not thread_pool.is_connected("jobs_complete", self, "brush_visuals_complete"):
		thread_pool.connect("jobs_complete", self, "brush_visuals_complete")

	print("Building visuals...")
	thread_pool.start_thread_jobs()

func build_brush_visuals(userdata):
	var brush_node = userdata[0]
	var entity_idx = userdata[1]
	var brush_idx = userdata[2]

	var entity_properties = map_reader.read_entity_properties(entity_idx)
	var brush = map_reader.read_entity_brush(entity_idx, brush_idx, get_valve_uvs(map_format), get_bitmask_format(map_format))

	var brush_collision_objects = brush_mapper.create_brush_collision_objects(entity_properties, brush, inverse_scale_factor)

	var brush_subnodes = []

	match mode:
		QodotEnums.MapMode.FACE_AXES:
			brush_subnodes = brush_mapper.create_brush_face_axes(brush, inverse_scale_factor)

		QodotEnums.MapMode.FACE_VERTICES:
			brush_subnodes = brush_mapper.create_brush_face_vertices(brush, inverse_scale_factor)

		QodotEnums.MapMode.BRUSH_MESHES:
			var face_meshes = brush_mapper.create_brush_meshes(entity_properties, brush, face_mapper, texture_mapper, base_texture_path, material_extension, texture_extension, default_material, inverse_scale_factor)
			for face_mesh in face_meshes:
				brush_subnodes.append(face_mesh)

	for subnode in brush_subnodes:
		brush_node.call_deferred("add_child", subnode)

func brush_visuals_complete():
	thread_pool.disconnect("jobs_complete", self, "brush_visuals_complete")

	print("Visual build complete.")

	build_complete()

func build_complete():
	print("Adding nodes to editor tree...")
	var edited_scene_root = get_tree().get_edited_scene_root()
	for child in get_children():
		recursive_set_owner(child, edited_scene_root)

	print("Cleaning up...")
	map_reader.close_map()

	var build_end_timestamp = OS.get_ticks_msec()
	var build_duration = build_end_timestamp - build_start_timestamp
	print("Build complete after ", build_duration * 0.001, " seconds.")


func recursive_set_owner(node, new_owner):
	node.set_owner(new_owner)
	for child in node.get_children():
		self.recursive_set_owner(child, new_owner)

# Cleanup
func _exit_tree() -> void:
	thread_pool.wait_to_finish()
