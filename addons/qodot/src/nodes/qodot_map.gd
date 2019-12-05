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

# File extension appended to textures specified in the .map file
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

var thread_pool = QodotThreadPool.new()

# Texture mapper
var texture_mapper = QodotTextureMapper.new()

## Setters
func set_reload(new_reload):
	if(reload != new_reload):
		update_map()

func set_max_build_threads(new_max_build_threads):
	if(max_build_threads != new_max_build_threads):
		max_build_threads = new_max_build_threads

		thread_pool.set_max_threads(max_build_threads)

## Map load handling
# Clears the map, loads the .map file from disk, parses it, and begins geometry generation
func update_map():
	if(Engine.is_editor_hint()):
		if(thread_pool.jobs_running() > 0 || thread_pool.jobs_pending() > 0):
			return

		clear_map()

		var map_file_obj = File.new()

		var err = map_file_obj.open(map_file, File.READ)
		if err != OK:
			QodotUtil.debug_print(['Error opening file: ', err])
			return err

		print("Beginning .map file read")
		var map_reader = QuakeMapReader.new()
		var map = map_reader.read_map_file(map_file_obj, get_valve_uvs(map_format), get_bitmask_format(map_format))
		print(".map file read complete")

		if(map != null):
			if(map.entities.size() > 0):
				var worldspawn = map.entities[0]
				if('message' in worldspawn.properties):
					name = worldspawn.properties['message']

			if not thread_pool.is_connected("jobs_complete", self, "entities_complete"):
				thread_pool.connect("jobs_complete", self, "entities_complete")

			print("Spawning entities...")
			for entity in map.entities:
				thread_pool.add_thread_job([self, "create_entity", [entity]])

		map_file_obj.close()

# Returns whether a given format uses Valve-style UVs
func get_valve_uvs(map_format: int):
	return map_format == QodotEnums.MapFormat.VALVE

# Returns the bimask format for a given map format
func get_bitmask_format(map_format: int):
	match(map_format):
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

## Business logic
func _exit_tree() -> void:
	thread_pool.wait_to_finish()

# Clears any existing children
func clear_map():
	for child in get_children():
		if(child.get_script() == QodotEntity):
			remove_child(child)
			child.queue_free()

# Creates a node representation of an entity and its child brushes
func create_entity(userdata):
	var entity = userdata[0]
	var thread = userdata[1]

	var parent_map_node = self

	var entity_node = QodotEntity.new()

	if('classname' in entity.properties):
		entity_node.name = entity.properties['classname']

	if('origin' in entity.properties):
		entity_node.translation = entity.properties['origin'] / inverse_scale_factor

	if('properties' in entity_node):
		entity_node.properties = entity.properties

	if(entity_mapper != null):
		var entity_spawned_node = entity_mapper.spawn_node_for_entity(entity)
		if(entity_spawned_node != null):
			entity_node.add_child(entity_spawned_node)
			if('angle' in entity.properties):
				entity_spawned_node.rotation.y = deg2rad(180 + entity.properties['angle'])

	self.call_deferred("add_child", entity_node)

	for brush in entity.brushes:
		create_brush([entity_node, entity, brush])

	thread_pool.call_deferred("finish_thread_job", thread)

func entities_complete():
	print("entities complete")
	if(is_inside_tree()):
		var tree = get_tree()
		if(tree != null):
			var edited_scene_root = tree.get_edited_scene_root()
			if(edited_scene_root != null):
				for child in get_children():
					self.recursive_add_editor(child, edited_scene_root)

func recursive_add_editor(node, edited_scene_root):
	node.set_owner(edited_scene_root)
	for child in node.get_children():
		self.recursive_add_editor(child, edited_scene_root)

# Creates a node representation of a brush
func create_brush(userdata):
	var parent_entity_node = userdata[0]
	var entity = userdata[1]
	var brush = userdata[2]

	var brush_node = QodotBrush.new()
	brush_node.name = 'Brush0'
	brush_node.translation = brush.center / inverse_scale_factor

	match mode:
		QodotEnums.MapMode.FACE_AXES:
			var face_axes_nodes = create_face_axes(brush)
			for face_axes_node in face_axes_nodes:
				brush_node.add_child(face_axes_node)

		QodotEnums.MapMode.FACE_VERTICES:
			var face_nodes = create_face_vertices(brush)
			for face_node in face_nodes:
				brush_node.add_child(face_node)

		QodotEnums.MapMode.BRUSH_MESHES:
			if(brush_mapper.should_spawn_brush_mesh(entity, brush)):
				var face_meshes = create_brush_meshes(entity, brush)
				for face_mesh in face_meshes:
					brush_node.add_child(face_mesh)

			if(brush_mapper.should_spawn_brush_collision(entity, brush)):
				var brush_collision_objects = create_brush_collision_objects(entity, brush)
				for collision_object in brush_collision_objects:
					brush_node.add_child(collision_object)

	parent_entity_node.call_deferred("add_child", brush_node)


func create_face_axes(brush: QuakeBrush):
	var face_axes = []

	for face in brush.faces:
		var face_axes_node = QuakePlaneAxes.new()
		face_axes_node.name = 'Plane0'
		face_axes_node.translation = (face.plane_vertices[0] - brush.center) / inverse_scale_factor

		face_axes_node.vertex_set = []
		for vertex in face.plane_vertices:
			face_axes_node.vertex_set.append(((vertex - face.plane_vertices[0]) / inverse_scale_factor))

		face_axes.append(face_axes_node)

	return face_axes

func create_face_vertices(brush: QuakeBrush):
	var face_nodes = []

	for face in brush.faces:
		var vertices = face.face_vertices
		var face_spatial = QodotSpatial.new()
		face_spatial.name = 'Face0'
		face_spatial.translation = (face.center - brush.center) / inverse_scale_factor
		face_nodes.append(face_spatial)

		for vertex in vertices:
			var vertex_node = Position3D.new()
			vertex_node.name = 'Point0'
			vertex_node.translation = vertex / inverse_scale_factor
			face_spatial.add_child(vertex_node)

	return face_nodes

func create_brush_meshes(entity: QuakeEntity, brush: QuakeBrush) -> Array:
	var brush_meshes = []

	for face in brush.faces:
		var spatial_material = texture_mapper.get_spatial_material(face, base_texture_path, material_extension, texture_extension, default_material)
		if(face_mapper.should_spawn_face_mesh(entity, brush, face)):
			var face_mesh_node = face_mapper.spawn_face_mesh(brush, face, texture_mapper, base_texture_path, material_extension, texture_extension, default_material, inverse_scale_factor)
			brush_meshes.append(face_mesh_node)

	return brush_meshes

func create_brush_collision_objects(entity: QuakeEntity, brush: QuakeBrush) -> Array:
	var collision_vertices = brush_mapper.get_brush_collision_vertices(entity, brush)

	var scaled_collision_vertices = PoolVector3Array()
	for collision_vertex in collision_vertices:
		scaled_collision_vertices.append(collision_vertex / inverse_scale_factor)

	var brush_collision_shape = brush_mapper.spawn_brush_collision_shape(entity, brush, scaled_collision_vertices)

	var brush_collision_object = brush_mapper.spawn_brush_collision_object(entity, brush)
	brush_collision_object.add_child(brush_collision_shape)

	return [brush_collision_object]
