tool
class_name QuakeMapNode
extends Spatial

const EPSILON = 0.0001
const TEXTURE_EMPTY = "__TB_empty"

enum Mode {
	PLANE_AXES,
	FACE_POINTS,
	BRUSH_MESHES
}

export(bool) var reload setget set_reload
export(Mode) var mode = Mode.BRUSH_MESHES setget set_mode
export(float) var scale_factor = 16.0 setget set_scale_factor
export(String, FILE, "*.map") var autoload_map_path setget set_autoload_map_path
export(String, DIR) var base_texture_path = "res://Textures" setget set_base_texture_path
export(String) var texture_extension = ".png"

var _winding_normal = Vector3.ZERO
var _winding_basis = Vector3.ZERO

# Setters
func set_reload(new_reload):
	if(reload != new_reload):
		if(Engine.is_editor_hint()):
			update_map()
			
func set_mode(new_mode):
	if(mode != new_mode):
		mode = new_mode
		
		if(Engine.is_editor_hint()):
			update_map()

func set_scale_factor(new_scale_factor):
	if(scale_factor != new_scale_factor):
		scale_factor = new_scale_factor
		
		if(Engine.is_editor_hint()):
			update_map()

func set_autoload_map_path(new_autoload_map_path):
	if(autoload_map_path != new_autoload_map_path):
		autoload_map_path = new_autoload_map_path
		
		if(Engine.is_editor_hint()):
			update_map()

func set_base_texture_path(new_base_texture_path):
	if(base_texture_path != new_base_texture_path):
		base_texture_path = new_base_texture_path
		
		if(Engine.is_editor_hint()):
			update_map()

func set_texture_extension(new_texture_extension):
	if(texture_extension != new_texture_extension):
		texture_extension = new_texture_extension
		
		if(Engine.is_editor_hint()):
			update_map()

func update_map():
	var autoload_map := load(autoload_map_path) as QuakeMap
	set_map(autoload_map)

# Business logic
func set_map(map: QuakeMap):
	clear_map()
	
	if(map != null):
		if(map.entities.size() > 0):
			var worldspawn = map.entities[0]
			if("message" in worldspawn.properties):
				name = worldspawn.properties["message"]
		for entity in map.entities:
			create_entity(self, entity)

func clear_map():
	for child in get_children():
		remove_child(child)
		child.queue_free()

func create_entity(parent, entity):
	var entity_node = null
	
	if("classname" in entity.properties):
		var classname = entity.properties["classname"]
		entity_node = spawn_entity_node(classname)
	else:
		entity_node.name = "Entity0"
	
	if("origin" in entity.properties):
		entity_node.translation = entity.properties["origin"] / scale_factor
		
	if("angle" in entity.properties):
		entity_node.rotation.y = deg2rad(180 + entity.properties["angle"])
	
	QodotUtil.add_child_editor(parent, entity_node)
	
	for brush in entity.brushes:
		create_brush(entity_node, brush, entity.properties)

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
	
	match mode:
		Mode.PLANE_AXES:
			var brush_node = QodotUtil.add_child_editor(parent, Spatial.new())
			brush_node.name = "Brush0"
			brush_node.translation = brush_center
			
			for plane in planes:
				var plane_axes = QodotUtil.add_child_editor(brush_node, PlaneAxes.new())
				plane_axes.name = "Plane0"
				plane_axes.translation = (plane.points[0] / scale_factor) - brush_center
				
				plane_axes.point_set = []
				for point in plane.points:
					plane_axes.point_set.append((point - plane.points[0]) / scale_factor)
		
		Mode.FACE_POINTS:
			var brush_node = QodotUtil.add_child_editor(parent, Spatial.new())
			brush_node.name = "Brush0"
			brush_node.translation = brush_center
			
			for plane_idx in sorted_local_face_vertices:
				var points = sorted_local_face_vertices[plane_idx]
				var plane_spatial = QodotUtil.add_child_editor(brush_node, Spatial.new())
				plane_spatial.name = "Plane0"
				plane_spatial.translation = face_centers[plane_idx] - brush_center
				
				for point in points:
					var point_node = QodotUtil.add_child_editor(plane_spatial, Position3D.new())
					point_node.name = "Point0"
					point_node.translation = point
		
		Mode.BRUSH_MESHES:
			var classname = null
			if("classname" in properties):
				classname = properties["classname"]
				
			var brush_node = null
			
			if(should_spawn_brush_mesh(classname)):
				brush_node = QodotUtil.add_child_editor(parent, MeshInstance.new())
				brush_node.name = "Brush0"
				brush_node.translation = brush_center
				
				# Create mesh
				var array_mesh = ArrayMesh.new()
				brush_node.set_mesh(array_mesh)
				
				for plane_idx in sorted_local_face_vertices:
					var plane = planes[plane_idx]
					var points = sorted_local_face_vertices[plane_idx]
					
					var surface_tool = SurfaceTool.new()
					surface_tool.begin(Mesh.PRIMITIVE_TRIANGLE_FAN)
					
					var normal = face_normals[plane_idx]
					surface_tool.add_normal(normal)
					
					
					var texture = null
					if(plane.texture != TEXTURE_EMPTY):
						var texturePath = base_texture_path + "/" + plane.texture + texture_extension
						texture = load(texturePath)
						
						if(texture != null):
							var spatial_material = SpatialMaterial.new()
							spatial_material.set_texture(SpatialMaterial.TEXTURE_ALBEDO, texture)
							surface_tool.set_material(spatial_material)
					
					var point_idx = 0
					for point in points:
						surface_tool.add_index(point_idx)
						
						var global_point = face_centers[plane_idx] + point
						
						if(texture != null):
							surface_tool.add_uv(
								get_uv(
									global_point,
									normal,
									texture,
									plane.uv,
									plane.rotation,
									plane.scale
								)
							)
						
						var local_point = global_point - brush_center
						surface_tool.add_vertex(local_point)
						point_idx += 1
					
					surface_tool.commit(array_mesh)
				
			# Create collision
			if(should_spawn_brush_collision(classname)):
				var collision_points = []
				for plane_idx in sorted_local_face_vertices:
					var points = sorted_local_face_vertices[plane_idx]
					for point in points:
						var global_point = face_centers[plane_idx] + point
						var local_point = global_point - brush_center
						collision_points.append(local_point)
				
				var brush_collision_object = null
				if(brush_node != null):
					brush_collision_object = QodotUtil.add_child_editor(brush_node, spawn_brush_collision_object(classname))
				else:
					brush_collision_object = QodotUtil.add_child_editor(parent, spawn_brush_collision_object(classname))
					brush_collision_object.name = "Brush0"
					brush_collision_object.translation = brush_center
				
				var brush_collision_shape = QodotUtil.add_child_editor(brush_collision_object, CollisionShape.new())
				var brush_convex_collision = ConvexPolygonShape.new()
				brush_convex_collision.set_points(collision_points)
				
				brush_collision_shape.set_shape(brush_convex_collision)
	
# Inheritance interface
func spawn_entity_node(classname: String) -> Node:
	var node = null
	
	if(classname.find("trigger") > -1):
		node = Spatial.new()
		node.name = classname + "0"
	elif(classname == "worldspawn"):
		node = Spatial.new()
		node.name = classname
	else:
		node = Position3D.new()
		node.name = classname + "0"
	
	return node

func should_spawn_brush_mesh(classname: String) -> bool:
	return classname.find("trigger") == -1
	
func should_spawn_brush_collision(classname: String) -> bool:
	return true

func spawn_brush_collision_object(classname: String) -> CollisionObject:
	var node = null
	
	if(classname.find("trigger") > -1):
		node = Area.new()
	else:
		node = StaticBody.new()
	
	return node

# Utility
func find_face_vertices(planes):
	var point_dict = {}
	
	var idx = 0
	for plane in planes:
		point_dict[idx] = []
		idx += 1
	
	var idx1 = 0
	for plane1 in planes:
		var idx2 = 0
		for plane2 in planes:
			var idx3 = 0
			for plane3 in planes:
				var point = QuakePlane.intersect_planes(plane1, plane2, plane3)
				
				if(point != null && QuakeBrush.point_in_hull(planes, point)):
					point /= scale_factor
					
					if(!point_dict[idx1].has(point)):
						point_dict[idx1].append(point)
					
					if(!point_dict[idx2].has(point)):
						point_dict[idx2].append(point)
					
					if(!point_dict[idx3].has(point)):
						point_dict[idx3].append(point)
					
				idx3 += 1
			idx2 += 1
		idx1 += 1
	
	return point_dict

func find_face_centers(face_vertices):
	var face_centers = {}
	
	for face_idx in face_vertices:
		var vertices = face_vertices[face_idx]
		
		var center = Vector3.ZERO
		for point in vertices:
			center += point
			
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
		vertices.sort_custom(self, "sort_local_face_vertices_internal")
		
		sorted_face_vertices[face_idx] = vertices
	
	return sorted_face_vertices

func sort_local_face_vertices_internal(a, b):
	return get_winding_rotation(a) < get_winding_rotation(b)

func get_winding_rotation(point):
	var u = _winding_basis
	var v = _winding_basis.normalized().cross(_winding_normal)
	
	var pu = point.dot(u)
	var pv = point.dot(v)
	
	return cartesian2polar(pu, pv).y
	
func get_uv(
	global_point: Vector3,
	normal: Vector3,
	texture: Texture,
	translation: Vector2,
	rotation: float,
	scale: Vector2) -> Vector2:
	var uv = Vector2.ZERO
	
	var du = abs(normal.dot(Vector3.UP))
	var dr = abs(normal.dot(Vector3.RIGHT))
	var df = abs(normal.dot(Vector3.BACK))
	
	if(du >= dr && du >= df):
		uv = Vector2(global_point.z, -global_point.x)
	elif(dr >= du && dr >= df):
		uv = Vector2(global_point.z, -global_point.y)
	elif(df >= du && df >= dr):
		uv = Vector2(global_point.x, -global_point.y)

	uv /=  texture.get_size() / scale_factor
	
	uv = uv.rotated(deg2rad(rotation))
	uv /= scale
	uv += translation / texture.get_size()
	
	return uv
	