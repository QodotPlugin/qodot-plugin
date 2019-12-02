class_name QodotMap
extends QodotSpatial
tool

### Spatial node for rendering a QuakeMap resource into an entity/brush tree

const TEXTURE_EMPTY = '__TB_empty'	# TrenchBroom empty texture string

enum Mode {
	FACE_AXES, 		# Debug visualization of raw plane data
	FACE_VERTICES,	# Debug visualization of intersecting plane vertices
	BRUSH_MESHES	# Full mesh representation with collision
}

# Pseudo-button for forcing a refresh after asset reimport
export(bool) var reload setget set_reload

# Rendering mode
export(Mode) var mode = Mode.BRUSH_MESHES setget set_mode

# Factor to scale the .map file's quake units down by
# (16 is a best-effort conversion from Quake 3 units to metric)
export(float) var inverse_scale_factor = 16.0 setget set_inverse_scale_factor

# .map Resource to auto-load when updating the map from the editor
# (Works around references being held and preventing refresh on reimport)
export(String, FILE, '*.map') var autoload_map_path setget set_autoload_map_path

# Base search path for textures specified in the .map file
export(String, DIR) var base_texture_path = 'res://textures' setget set_base_texture_path

# File extension appended to textures specified in the .map file
export(String) var texture_extension = '.png'

export(Script) var entity_mapper = QodotEntityMapper

# Internal variables for calculating vertex winding
var _winding_normal = Vector3.ZERO
var _winding_basis = Vector3.ZERO


## Inheritance interface
## Override these functions to control game-specific tree population

# Determine whether the given .map classname should create a mesh
func should_spawn_brush_mesh(classname: String) -> bool:
	return classname.find('trigger') == -1

# Determine whether the given .map classname should create a collision object
func should_spawn_brush_collision(classname: String) -> bool:
	return true

# Create and return a CollisionObject for the given .map classname
func spawn_brush_collision_object(classname: String) -> CollisionObject:
	var node = null

	if(classname.find('trigger') > -1):
		node = Area.new()
	else:
		node = StaticBody.new()

	return node

## Setters
func set_reload(new_reload):
	if(reload != new_reload):
		update_map()

func set_mode(new_mode):
	if(mode != new_mode):
		mode = new_mode
		update_map()

func set_inverse_scale_factor(new_inverse_scale_factor):
	if(inverse_scale_factor != new_inverse_scale_factor):
		inverse_scale_factor = new_inverse_scale_factor
		update_map()

func set_autoload_map_path(new_autoload_map_path):
	if(autoload_map_path != new_autoload_map_path):
		autoload_map_path = new_autoload_map_path
		update_map()

func set_base_texture_path(new_base_texture_path):
	if(base_texture_path != new_base_texture_path):
		base_texture_path = new_base_texture_path
		update_map()

func set_texture_extension(new_texture_extension):
	if(texture_extension != new_texture_extension):
		texture_extension = new_texture_extension
		update_map()

## Map autoload handler
func update_map():
	if(Engine.is_editor_hint()):
		var autoload_map := load(autoload_map_path) as QuakeMap
		set_map(autoload_map)

## Built-in overrides
func _ready():
	update_map()

## Business logic
# Clears any existing children,
# then renders the provided QuakeMap into an entity/brush tree
func set_map(map: QuakeMap):
	if(map != null):
		clear_map()

		if(map.entities.size() > 0):
			var worldspawn = map.entities[0]
			if('message' in worldspawn.properties):
				name = worldspawn.properties['message']
		for entity in map.entities:
			create_entity(self, entity)

# Clears any existing children
func clear_map():
	for child in get_children():
		if(child.get_script() == QodotEntity):
			remove_child(child)
			child.queue_free()

# Creates a node representation of an entity and its child brushes
func create_entity(parent, entity):
	var entity_node = QodotUtil.add_child_editor(parent, QodotEntity.new())

	if('classname' in entity.properties):
		entity_node.name = entity.properties['classname']

	if('origin' in entity.properties):
		entity_node.translation = entity.properties['origin'] / inverse_scale_factor

	if('angle' in entity.properties):
		entity_node.rotation.y = deg2rad(180 + entity.properties['angle'])

	if('properties' in entity_node):
		entity_node.properties = entity.properties

	if(entity_mapper != null):
		var entity_spawned_node = entity_mapper.spawn_node_for_entity(entity)
		if(entity_spawned_node != null):
			QodotUtil.add_child_editor(entity_node, entity_spawned_node)

	for brush in entity.brushes:
		create_brush(entity_node, brush, entity.properties)

# Creates a node representation of a brush
func create_brush(parent, brush, properties):
	var planes = brush.planes
	var face_vertices = find_face_vertices(planes)
	var face_normals = find_face_normals(planes)
	var face_centers = find_face_centers(face_vertices)
	var local_face_vertices = find_local_face_vertices(face_vertices, face_centers)
	var sorted_local_face_vertices = sort_local_face_vertices(local_face_vertices, face_normals)

	var brush_center = Vector3.ZERO
	for center_idx in face_centers:
		var center = face_centers[center_idx]
		brush_center += center
	brush_center /= face_centers.size()

	var brush_node = QodotUtil.add_child_editor(parent, QodotBrush.new())
	brush_node.name = 'Brush0'
	brush_node.translation = brush_center

	match mode:
		Mode.FACE_AXES:
			for plane in planes:
				var face_axes = QodotUtil.add_child_editor(brush_node, QuakePlaneAxes.new())
				face_axes.name = 'Plane0'
				face_axes.translation = (plane.vertices[0] / inverse_scale_factor) - brush_center

				face_axes.vertex_set = []
				for vertex in plane.vertices:
					face_axes.vertex_set.append((vertex - plane.vertices[0]) / inverse_scale_factor)

		Mode.FACE_VERTICES:
			for plane_idx in sorted_local_face_vertices:
				var vertices = sorted_local_face_vertices[plane_idx]
				var plane_spatial = QodotUtil.add_child_editor(brush_node, QodotSpatial.new())
				plane_spatial.name = 'Face0'
				plane_spatial.translation = face_centers[plane_idx] - brush_center

				for vertex in vertices:
					var vertex_node = QodotUtil.add_child_editor(plane_spatial, Position3D.new())
					vertex_node.name = 'Point0'
					vertex_node.translation = vertex

		Mode.BRUSH_MESHES:
			var classname = null
			if('classname' in properties):
				classname = properties['classname']

			if(should_spawn_brush_mesh(classname)):
				# Create mesh
				for plane_idx in sorted_local_face_vertices:
					var plane = planes[plane_idx]
					var vertices = sorted_local_face_vertices[plane_idx]

					var surface_tool = SurfaceTool.new()
					surface_tool.begin(Mesh.PRIMITIVE_TRIANGLE_FAN)

					var normal = face_normals[plane_idx]
					surface_tool.add_normal(normal)


					var texture = null
					if(plane.texture != TEXTURE_EMPTY):
						var texturePath = base_texture_path + '/' + plane.texture + texture_extension
						texture = load(texturePath)

						if(texture != null):
							var spatial_material = SpatialMaterial.new()
							spatial_material.set_texture(SpatialMaterial.TEXTURE_ALBEDO, texture)
							surface_tool.set_material(spatial_material)

					var vertex_idx = 0
					for vertex in vertices:
						surface_tool.add_index(vertex_idx)

						var global_vertex = face_centers[plane_idx] + vertex

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

						var local_vertex = global_vertex - face_centers[plane_idx]
						surface_tool.add_vertex(local_vertex)
						vertex_idx += 1

					var face_mesh_node = QodotUtil.add_child_editor(brush_node, MeshInstance.new())
					face_mesh_node.name = 'Face0'
					face_mesh_node.translation = face_centers[plane_idx] - brush_center
					face_mesh_node.set_mesh(surface_tool.commit())

			# Create collision
			if(should_spawn_brush_collision(classname)):
				var collision_vertices = []
				for plane_idx in sorted_local_face_vertices:
					var vertices = sorted_local_face_vertices[plane_idx]
					for vertex in vertices:
						var global_vertex = face_centers[plane_idx] + vertex
						var local_vertex = global_vertex - brush_center
						collision_vertices.append(local_vertex)

				var brush_collision_object = QodotUtil.add_child_editor(brush_node, spawn_brush_collision_object(classname))

				var brush_collision_shape = QodotUtil.add_child_editor(brush_collision_object, CollisionShape.new())
				var brush_convex_collision = ConvexPolygonShape.new()
				brush_convex_collision.set_points(collision_vertices)

				brush_collision_shape.set_shape(brush_convex_collision)

# Utility
func find_face_vertices(planes):
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

					if(!vertex_dict[idx1].has(vertex)):
						vertex_dict[idx1].append(vertex)

					if(!vertex_dict[idx2].has(vertex)):
						vertex_dict[idx2].append(vertex)

					if(!vertex_dict[idx3].has(vertex)):
						vertex_dict[idx3].append(vertex)

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

func sort_local_face_vertices(local_face_vertices, face_normals):
	var sorted_face_vertices = {}

	for face_idx in local_face_vertices:
		var vertices = local_face_vertices[face_idx]
		var normal = face_normals[face_idx]

		_winding_normal = normal
		_winding_basis = vertices[0]
		vertices.sort_custom(self, 'sort_local_face_vertices_internal')

		sorted_face_vertices[face_idx] = vertices

	return sorted_face_vertices

func sort_local_face_vertices_internal(a, b):
	return get_winding_rotation(a) < get_winding_rotation(b)

func get_winding_rotation(vertex):
	var u = _winding_basis
	var v = _winding_basis.normalized().cross(_winding_normal)

	var pu = vertex.dot(u)
	var pv = vertex.dot(v)

	return cartesian2polar(pu, pv).y

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
