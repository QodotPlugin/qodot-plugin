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

# Instances
var map_reader = QuakeMapReader.new()
var thread_pool = QodotThreadPool.new()
var texture_mapper = QodotTextureMapper.new()

## Setters
func set_reload(new_reload):
	if reload != new_reload:
		if Engine.is_editor_hint():
			clear_map()

			var map = map_reader.read_map_file(map_file, get_valve_uvs(map_format), get_bitmask_format(map_format))
			if not map_file:
				print("Error: Invalid map file")
				return

			build_map(map)

func set_max_build_threads(new_max_build_threads):
	if max_build_threads != new_max_build_threads:
		max_build_threads = new_max_build_threads
		thread_pool.set_max_threads(max_build_threads)

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

# Clears any existing QodotEntity children
func clear_map():
	for child in get_children():
		if child.get_script() == QodotEntity:
			remove_child(child)
			child.queue_free()

# Kicks off the map building process
func build_map(map: QuakeMap):
	if thread_pool.jobs_running() > 0 || thread_pool.jobs_pending() > 0:
		print("Skipping build: Already in progress")
		return

	if not map:
		print('Skipping build: Invalid .map file')
		return

	print("Building map...")

	if map.entities.size() > 0:
		var worldspawn = map.entities[0]
		if 'message' in worldspawn.properties:
			name = worldspawn.properties['message']

	if not thread_pool.is_connected("jobs_complete", self, "entities_complete"):
		thread_pool.connect("jobs_complete", self, "entities_complete")

	print("Queueing ", map.entities.size(), " entities for building")
	for entity_idx in range(0, map.entities.size()):
		var entity = map.entities[entity_idx]
		thread_pool.add_thread_job([self, "build_entity", [entity_idx, map]])

# Creates a node representation of an entity and its child brushes
func build_entity(userdata):
	var entity_idx = userdata[0]
	var map = userdata[1]

	var entity = map.entities[entity_idx]

	print("Building entity ", entity_idx + 1, " of ", map.entities.size())

	if entity_mapper != null:
		var entity_node = entity_mapper.spawn_entity(entity, inverse_scale_factor)
		self.call_deferred("add_child", entity_node)

		for brush_idx in range(0, entity.brushes.size()):
			var brush = entity.brushes[brush_idx]
			build_brush([entity_node, entity, brush])

# Creates a node representation of a brush
func build_brush(userdata):
	var entity_node = userdata[0]
	var entity = userdata[1]
	var brush = userdata[2]

	var brush_node = QodotBrush.new()
	brush_node.name = 'Brush0'
	brush_node.translation = brush.center / inverse_scale_factor

	match mode:
		QodotEnums.MapMode.FACE_AXES:
			var face_axes_nodes = face_mapper.create_face_axes(brush)
			for face_axes_node in face_axes_nodes:
				brush_node.add_child(face_axes_node)

		QodotEnums.MapMode.FACE_VERTICES:
			var face_nodes = face_mapper.create_face_vertices(brush)
			for face_node in face_nodes:
				brush_node.add_child(face_node)

		QodotEnums.MapMode.BRUSH_MESHES:
			if brush_mapper.should_spawn_brush_mesh(entity, brush):
				var face_meshes = brush_mapper.create_brush_meshes(entity, brush, face_mapper, texture_mapper, base_texture_path, material_extension, texture_extension, default_material, inverse_scale_factor)
				for face_mesh in face_meshes:
					brush_node.add_child(face_mesh)

			if brush_mapper.should_spawn_brush_collision(entity, brush):
				var brush_collision_objects = brush_mapper.create_brush_collision_objects(entity, brush, inverse_scale_factor)
				for collision_object in brush_collision_objects:
					brush_node.add_child(collision_object)

	entity_node.add_child(brush_node)

# Build completion event, recursively adds child nodes to the editor tree
func entities_complete():
	print("Build complete, populating editor tree...")
	if is_inside_tree():
		var tree = get_tree()
		if tree:
			var edited_scene_root = tree.get_edited_scene_root()
			if edited_scene_root:
				for child in get_children():
					self.recursive_set_owner(child, edited_scene_root)

func recursive_set_owner(node, new_owner):
	node.set_owner(new_owner)
	for child in node.get_children():
		self.recursive_set_owner(child, new_owner)

# Cleanup
func _exit_tree() -> void:
	thread_pool.wait_to_finish()
