class_name QodotMap
extends QodotSpatial
tool

### Spatial node for rendering a QuakeMap resource into an entity/brush tree

const TEXTURE_EMPTY = '__TB_empty'	# TrenchBroom empty texture string

# Pseudo-button for forcing a refresh after asset reimport
export(bool) var reload setget set_reload

# Map file format
export(QodotEnums.MapFormat) var map_format = QodotEnums.MapFormat.STANDARD setget set_map_format

# Rendering mode
export(QodotEnums.MapMode) var mode = QodotEnums.MapMode.BRUSH_MESHES setget set_mode

# Factor to scale the .map file's quake units down by
# (16 is a best-effort conversion from Quake 3 units to metric)
export(float) var inverse_scale_factor = 16.0 setget set_inverse_scale_factor

# .map Resource to auto-load when updating the map from the editor
# (Works around references being held and preventing refresh on reimport)
export(String, FILE, '*.map') var map_file setget set_map_file

# Base search path for textures specified in the .map file
export(String, DIR) var base_texture_path = 'res://textures' setget set_base_texture_path

# File extension appended to textures specified in the .map file
export(String) var material_extension = '.tres' setget set_material_extension
export(String) var texture_extension = '.png' setget set_texture_extension

# Materials
export (SpatialMaterial) var default_material setget set_default_material

# Mappers used to control tree population
export(Script) var entity_mapper = QodotEntityMapper
export(Script) var brush_mapper = QodotBrushMapper
export(Script) var face_mapper = QodotFaceMapper

# Threads
var free_threads = []
var busy_threads = []
var pending_jobs = []

func add_threads(count):
	for idx in range(0, count):
		free_threads.append(Thread.new())

func add_thread_job(job):
	pending_jobs.append(job)
	start_thread_job()

func start_thread_job():
	if(pending_jobs.size() > 0):
		if(free_threads.size() > 0):
			var job = pending_jobs.pop_front()
			var thread = free_threads.pop_front()
			var params = job[2]
			params.append(thread)
			thread.start(job[0], job[1], params)
			busy_threads.append(thread)

func finish_thread_job(thread):
	busy_threads.remove(busy_threads.find(thread))
	thread.wait_to_finish()
	free_threads.append(thread)
	start_thread_job()

# Texture directory accessor
var texture_directory = Directory.new()

# Material and texture caches
var material_dict = {}
var texture_dict = {}

# Last generated map MD5
export(String) var last_md5 = null

## Setters
func set_reload(new_reload):
	if(reload != new_reload):
		update_map()

func set_status(new_status):
	pass

func set_mode(new_mode):
	if(mode != new_mode):
		mode = new_mode

func set_map_format(new_map_format):
	if(map_format != new_map_format):
		map_format = new_map_format

func set_inverse_scale_factor(new_inverse_scale_factor):
	if(inverse_scale_factor != new_inverse_scale_factor):
		inverse_scale_factor = new_inverse_scale_factor

func set_map_file(new_map_file):
	if(map_file != new_map_file):
		map_file = new_map_file

func set_base_texture_path(new_base_texture_path):
	if(base_texture_path != new_base_texture_path):
		base_texture_path = new_base_texture_path

func set_material_extension(new_material_extension):
	if(material_extension != new_material_extension):
		material_extension = new_material_extension

func set_texture_extension(new_texture_extension):
	if(texture_extension != new_texture_extension):
		texture_extension = new_texture_extension

func set_default_material(new_default_material):
	if(default_material != new_default_material):
		default_material = new_default_material

## Map load handling
# Clears the map, loads the .map file from disk, parses it, and begins geometry generation
func update_map():
	if(Engine.is_editor_hint()):
		if(pending_jobs.size() > 0 || busy_threads.size() > 0):
			return

		var map_file_obj = File.new()

		var err = map_file_obj.open(map_file, File.READ)
		if err != OK:
			QodotUtil.debug_print(['Error opening file: ', err])
			return err

		var file_md5 = map_file_obj.get_md5(map_file)
		if(last_md5 == file_md5):
			print("File unchanged, nothing to do.")
		else:
			print("File changed")

		clear_map()

		print(file_md5)
		last_md5 = file_md5

		print("Beginning .map file read")
		var map_reader = QuakeMapReader.new()
		var map = map_reader.read_map_file(map_file_obj, get_valve_uvs(map_format), get_bitmask_format(map_format))
		print(".map file read complete")

		if(map != null):
			if(map.entities.size() > 0):
				var worldspawn = map.entities[0]
				if('message' in worldspawn.properties):
					name = worldspawn.properties['message']

			if(free_threads.size() == 0 && busy_threads.size() == 0):
				add_threads(4)

			print("Spawning entities...")
			for entity in map.entities:
				add_thread_job([self, "create_entity", [entity]])

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
	for thread in busy_threads:
		thread.wait_to_finish()

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

	call_deferred("add_child", entity_node)

	for brush in entity.brushes:
		create_brush([entity_node, brush, entity])

	if(busy_threads.size() == 1 && pending_jobs.size() == 0):
		self.call_deferred("entities_complete")

	self.call_deferred("finish_thread_job", thread)

func entities_complete():
	print("entity spawn complete")
	if(is_inside_tree()):
		var tree = get_tree()
		if(tree != null):
			var edited_scene_root = tree.get_edited_scene_root()
			if(edited_scene_root != null):
				for child in get_children():
					recursive_add_editor(child, edited_scene_root)

func recursive_add_editor(node, edited_scene_root):
	node.set_owner(edited_scene_root)
	for child in node.get_children():
		recursive_add_editor(child, edited_scene_root)

# Creates a node representation of a brush
func create_brush(userdata):
	var parent_entity_node = userdata[0]
	var brush = userdata[1]
	var parent_entity = userdata[2]

	var planes = brush.planes
	var brush_center = brush.center / inverse_scale_factor

	var face_vertices = find_face_vertices(brush)
	var face_normals = find_face_normals(planes)
	var face_centers = find_face_centers(face_vertices)
	var sorted_local_face_vertices = sort_local_face_vertices(face_vertices, face_centers, face_normals)

	var brush_node = QodotBrush.new()
	brush_node.name = 'Brush0'
	brush_node.translation = brush_center

	match mode:
		QodotEnums.MapMode.FACE_AXES:
			for plane in planes:
				var face_axes = QuakePlaneAxes.new()
				face_axes.name = 'Plane0'
				face_axes.translation = (plane.vertices[0] / inverse_scale_factor)

				face_axes.vertex_set = []
				for vertex in plane.vertices:
					face_axes.vertex_set.append((vertex - plane.vertices[0]) / inverse_scale_factor)

				brush_node.add_child(face_axes)

		QodotEnums.MapMode.FACE_VERTICES:
			for plane_idx in face_vertices:
				var vertices = sorted_local_face_vertices[plane_idx]
				var plane_spatial = QodotSpatial.new()
				plane_spatial.name = 'Face0'
				plane_spatial.translation = face_centers[plane_idx]

				for vertex in vertices:
					var vertex_node = Position3D.new()
					vertex_node.name = 'Point0'
					vertex_node.translation = vertex - plane_spatial.translation
					plane_spatial.add_child(vertex_node)

				brush_node.call_deferred("add_child", plane_spatial)

		QodotEnums.MapMode.BRUSH_MESHES:
			var classname = null
			if('classname' in parent_entity.properties):
				classname = parent_entity.properties['classname']

			if(brush_mapper.should_spawn_brush_mesh(brush, parent_entity)):
				for plane_idx in sorted_local_face_vertices:
					var plane = planes[plane_idx]
					if(face_mapper.should_spawn_face_mesh(plane, brush, parent_entity)):
						var vertices = sorted_local_face_vertices[plane_idx]

						var surface_tool = SurfaceTool.new()
						surface_tool.begin(Mesh.PRIMITIVE_TRIANGLE_FAN)

						var normal = face_normals[plane_idx]
						surface_tool.add_normal(normal)

						if(plane.uv.size() == 2):
							# Standard format tangents
							surface_tool.add_tangent(get_standard_tangent(normal))
						elif(plane.uv.size() == 8):
							# Valve format tangents
							surface_tool.add_tangent(get_valve_tangent(normal, plane.uv))

						var texture = null
						texture_directory.change_dir(base_texture_path)

						if(plane.texture != TEXTURE_EMPTY):
							var texture_path = base_texture_path + '/' + plane.texture + texture_extension
							if(!texture_path in texture_dict && texture_directory.file_exists(texture_path)):
								var loaded_texture: Texture = load(texture_path)
								texture_dict[texture_path] = loaded_texture

							if(texture_path in texture_dict):
								texture = texture_dict[texture_path]

							var material_path = base_texture_path + '/' + plane.texture + material_extension

							if(!material_path in material_dict && texture_directory.file_exists(material_path)):
								var loaded_material: SpatialMaterial = load(material_path)
								material_dict[material_path] = loaded_material

							if(material_path in material_dict):
								surface_tool.set_material(material_dict[material_path])
							else:
								if(texture != null):
									var spatial_material = null
									if(default_material != null):
										spatial_material = default_material.duplicate()
									else:
										spatial_material = SpatialMaterial.new()

									spatial_material.set_texture(SpatialMaterial.TEXTURE_ALBEDO, texture)

									var normal_tex = get_pbr_texture(plane.texture, 'normal')
									if(normal_tex):
										spatial_material.normal_enabled = true
										spatial_material.set_texture(SpatialMaterial.TEXTURE_NORMAL, normal_tex)

									var metallic_tex = get_pbr_texture(plane.texture, 'metallic')
									if(metallic_tex):
										spatial_material.set_texture(SpatialMaterial.TEXTURE_METALLIC, metallic_tex)

									var roughness_tex = get_pbr_texture(plane.texture, 'roughness')
									if(roughness_tex):
										spatial_material.set_texture(SpatialMaterial.TEXTURE_ROUGHNESS, roughness_tex)

									var emissive_tex = get_pbr_texture(plane.texture, 'emissive')
									if(emissive_tex):
										spatial_material.emission_enabled = true
										spatial_material.set_texture(SpatialMaterial.TEXTURE_EMISSION, emissive_tex)

									var ao_tex = get_pbr_texture(plane.texture, 'ao')
									if(ao_tex):
										spatial_material.ao_enabled = true
										spatial_material.set_texture(SpatialMaterial.TEXTURE_AMBIENT_OCCLUSION, ao_tex)

									var depth_tex = get_pbr_texture(plane.texture, 'depth')
									if(depth_tex):
										spatial_material.depth_enabled = true
										spatial_material.set_texture(SpatialMaterial.TEXTURE_DEPTH, depth_tex)

									material_dict[material_path] = spatial_material
									surface_tool.set_material(spatial_material)

						var vertex_idx = 0
						for vertex in vertices:
							surface_tool.add_index(vertex_idx)

							var global_vertex = vertex + brush_center

							if(texture != null):
								var uv = null

								if(plane.uv.size() == 2):
									uv = get_standard_uv(
											global_vertex,
											normal,
											texture,
											plane.uv,
											plane.rotation,
											plane.scale
										)
								elif(plane.uv.size() == 8):
									uv = get_valve_uv(
											global_vertex,
											normal,
											texture,
											plane.uv,
											plane.rotation,
											plane.scale
										)

								if(uv != null):
									surface_tool.add_uv(uv)

							surface_tool.add_vertex(vertex - face_centers[plane_idx])
							vertex_idx += 1

						var face_mesh_node = MeshInstance.new()
						face_mesh_node.name = 'Face0'
						face_mesh_node.translation = face_centers[plane_idx]
						face_mesh_node.set_mesh(surface_tool.commit())
						brush_node.add_child(face_mesh_node)

			# Create collision
			if(brush_mapper.should_spawn_brush_collision(brush, parent_entity)):
				var collision_vertices = []
				for plane_idx in sorted_local_face_vertices:
					var vertices = sorted_local_face_vertices[plane_idx]
					for vertex in vertices:

						var vertex_present = false
						for collision_vertex in collision_vertices:
							if((vertex - collision_vertex).length() < 0.001):
								vertex_present = true

						if(!vertex_present):
							collision_vertices.append(vertex)

				var brush_collision_object = brush_mapper.spawn_brush_collision_object(brush, parent_entity)


				var brush_convex_collision = ConvexPolygonShape.new()
				brush_convex_collision.set_points(collision_vertices)

				var brush_collision_shape = CollisionShape.new()
				brush_collision_shape.set_shape(brush_convex_collision)
				brush_collision_object.add_child(brush_collision_shape)

				brush_node.add_child(brush_collision_object)

	parent_entity_node.call_deferred("add_child", brush_node)

# Utility
func find_face_vertices(brush):
	var planes = brush.planes

	for plane in planes:
		plane.vertices[0] -= brush.center
		plane.vertices[1] -= brush.center
		plane.vertices[2] -= brush.center

	var vertex_dict = {}

	var idx = 0
	for plane in planes:
		vertex_dict[idx] = []
		idx += 1

	var idx1 = 0
	for plane1 in planes:
		var idx2 = 0
		for plane2 in planes:
			var idx3 = 0
			for plane3 in planes:
				var vertex = QuakePlane.intersect_planes(plane1, plane2, plane3)

				if(vertex != null && QuakeBrush.vertex_in_hull(planes, vertex)):
					vertex /= inverse_scale_factor

					var vertex_exists = false

					for comp_vertex in vertex_dict[idx1]:
						if((comp_vertex - vertex).length() < 0.0001):
							vertex_exists = true

					if not vertex_exists:
						vertex_dict[idx1].append(vertex)

				idx3 += 1
			idx2 += 1
		idx1 += 1

	return vertex_dict

func find_face_centers(face_vertices):
	var face_centers = {}

	for face_idx in face_vertices:
		var vertices = face_vertices[face_idx]

		var center = Vector3.ZERO
		for vertex in vertices:
			center += vertex

		face_centers[face_idx] = center / vertices.size()

	return face_centers

func find_face_normals(planes):
	var face_normals = {}

	for plane_idx in range(0, planes.size()):
		var plane = planes[plane_idx]
		face_normals[plane_idx] = QuakePlane.get_normal(plane)

	return face_normals

func find_local_face_vertices(face_vertices, face_centers):
	var local_face_vertices = {}

	for face_idx in face_vertices:
		var vertices = face_vertices[face_idx]

		for vertex in vertices:
			if(!face_idx in local_face_vertices):
				local_face_vertices[face_idx] = []

			local_face_vertices[face_idx].append(vertex - face_centers[face_idx])

	return local_face_vertices

var _winding_center = Vector3.ZERO
var _winding_normal = Vector3.ZERO
var _winding_basis = Vector3.ZERO
func sort_local_face_vertices(local_face_vertices, face_centers, face_normals):
	var sorted_face_vertices = {}

	for face_idx in local_face_vertices:
		var vertices = local_face_vertices[face_idx]

		_winding_center = face_centers[face_idx]
		_winding_normal = face_normals[face_idx]
		_winding_basis = vertices[1] - vertices[0]
		vertices.sort_custom(self, 'sort_local_face_vertices_internal')

		sorted_face_vertices[face_idx] = vertices

	return sorted_face_vertices

func sort_local_face_vertices_internal(a, b):
	return get_winding_rotation(a) > get_winding_rotation(b)

func get_face_coords(vertex):
	var local_vertex = vertex - _winding_center

	var u = _winding_basis.normalized()
	var v = u.cross(_winding_normal).normalized()

	var pu = -local_vertex.dot(u)
	var pv = local_vertex.dot(v)

	return Vector2(pu, pv)

func get_winding_rotation(vertex):
	var vertex_uv = get_face_coords(vertex)
	var angle = vertex_uv.angle()
	return angle

func get_standard_uv(
	global_vertex: Vector3,
	normal: Vector3,
	texture: Texture,
	uv: PoolRealArray,
	rotation: float,
	scale: Vector2) -> Vector2:
	var uv_out = Vector2.ZERO

	var du = abs(normal.dot(Vector3.UP))
	var dr = abs(normal.dot(Vector3.RIGHT))
	var df = abs(normal.dot(Vector3.BACK))

	if(du >= dr && du >= df):
		uv_out = Vector2(global_vertex.z, -global_vertex.x)
	elif(dr >= du && dr >= df):
		uv_out = Vector2(global_vertex.z, -global_vertex.y)
	elif(df >= du && df >= dr):
		uv_out = Vector2(global_vertex.x, -global_vertex.y)

	uv_out /=  texture.get_size() / inverse_scale_factor

	uv_out = uv_out.rotated(deg2rad(rotation))
	uv_out /= scale
	uv_out += Vector2(uv[0], uv[1]) / texture.get_size()

	return uv_out


func get_valve_uv(
	global_vertex: Vector3,
	normal: Vector3,
	texture: Texture,
	uv: PoolRealArray,
	rotation: float,
	scale: Vector2) -> Vector2:
	var uv_out = Vector2.ZERO

	var u_axis = Vector3(uv[1], uv[2], uv[0])
	var u_shift = uv[3]
	var v_axis = Vector3(uv[5], uv[6], uv[4])
	var v_shift = uv[7]

	uv_out.x = u_axis.dot(global_vertex)
	uv_out.y = v_axis.dot(global_vertex)

	var texture_size = texture.get_size()

	uv_out /=  texture_size / inverse_scale_factor
	uv_out /= scale
	uv_out += Vector2(u_shift, v_shift) / texture_size

	return uv_out

# Tangent functions to work around broken auto-generated ones
# Also incorrect for now,
# but prevents materials with depth mapping from crashing the graphics driver
func get_standard_tangent(normal: Vector3) -> Plane:
	return Plane(normal.cross(Vector3.UP).normalized(), 0.0)

func get_valve_tangent(normal, uv: PoolRealArray) -> Plane:
	return Plane(normal.cross(Vector3.UP).normalized(), 0.0)

# PBR texture fetching
func get_pbr_texture(texture, suffix):
	var texture_comps = texture.split('/')
	var texture_group = texture_comps[0]
	var texture_name = texture_comps[1]
	var path = base_texture_path + '/' + texture_group + '/' + texture_name + '/' + texture_name + '_' + suffix + texture_extension

	if(path in texture_dict):
		return texture_dict[path]
	else:
		texture_directory.change_dir(base_texture_path)
		if(texture_directory.file_exists(path)):
			var tex = load(path)
			if(tex):
				texture_dict[path] = tex
				return tex

	return null
