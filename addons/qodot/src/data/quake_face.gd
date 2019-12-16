class_name QuakeFace

# Resource representation of a .map file brush plane

var plane_vertices: PoolVector3Array
var plane: Plane
var normal: Vector3

var face_vertices = PoolVector3Array()
var center: Vector3

var texture: String

var uv: PoolRealArray
var rotation: float
var scale: Vector2

var bitmask_params: PoolIntArray

func _init(face_data: Array):
	var plane_vertices: PoolVector3Array = PoolVector3Array(face_data[0])
	var texture: String = face_data[1]
	var uv: PoolRealArray = PoolRealArray(face_data[2])
	var rotation: float = face_data[3]
	var scale: Vector2 = face_data[4]
	var bitmask_params: PoolIntArray = PoolIntArray(face_data[5])

	self.plane_vertices = plane_vertices
	self.plane = Plane(plane_vertices[0], plane_vertices[1], plane_vertices[2])
	self.normal = self.plane.normal

	self.texture = texture

	self.uv = uv
	self.rotation = rotation
	self.scale = scale
	self.bitmask_params = bitmask_params

# Get the plane's distance from the world origin
func get_distance() -> float:
	return self.plane.d

# Intersect three brush planes to form a vertex
func intersect_faces(face2, face3):
	return self.plane.intersect_3(face2.plane, face3.plane)

func add_unique_vertex(vertex):
	if not self.has_vertex(vertex):
		self.face_vertices.append(vertex)

func has_vertex(vertex):
	for comp_vertex in self.face_vertices:
		if((comp_vertex - vertex).length() < 0.0001):
			return true

	return false

func set_center(new_center):
	self.center = new_center

func get_vertices(global_space: bool) -> PoolVector3Array:
	var vertices = PoolVector3Array()
	for vertex in face_vertices:
		if(global_space):
			vertices.append(vertex + self.center)
		else:
			vertices.append(vertex)
	return vertices

func get_triangles(global_space: bool) -> PoolVector3Array:
	var triangles = PoolVector3Array()
	var vertices = get_vertices(global_space)

	for vertex_idx in range(1, vertices.size() - 1):
		triangles.append(vertices[0])
		triangles.append(vertices[vertex_idx])
		triangles.append(vertices[vertex_idx + 1])

	return triangles

func get_mesh(surface_tool: SurfaceTool, texture_size: Vector2, color: Color, global_space: bool):
	var vertices = get_vertices(global_space)
	var uvs = PoolVector2Array()
	var colors = PoolColorArray()
	var uv2s = PoolVector2Array()
	var normals = PoolVector3Array()
	var tangents = []

	for vertex in face_vertices:
		var uv = get_uv(vertex, texture_size)
		if uv:
			uvs.append(uv)
			uv2s.append(uv)
		else:
			uvs.append(Vector2.ZERO)
			uv2s.append(Vector2.ZERO)

		colors.append(color)

		normals.append(self.normal)

		var tangent = get_tangent()
		tangents.append(tangent)

	surface_tool.add_triangle_fan(vertices, uvs, colors, uv2s, normals, tangents)


func get_uv(vertex: Vector3, texture_size: Vector2):
	if(uv.size() == 2):
		return get_standard_uv(
				vertex + self.center,
				texture_size
			)
	elif(uv.size() == 8):
		return get_valve_uv(
				vertex + self.center,
				texture_size
			)
	else:
		print('Error: Unknown UV format')
		return null

func get_standard_uv(
	global_vertex: Vector3,
	texture_size: Vector2
	):
	if(uv.size() != 2):
		print("Error: not a Standard-format UV array")
		return null

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

	uv_out = uv_out.rotated(deg2rad(rotation))
	uv_out /= texture_size
	uv_out /= scale
	uv_out += Vector2(uv[0], uv[1]) / texture_size

	return uv_out


func get_valve_uv(
	global_vertex: Vector3,
	texture_size: Vector2
	):
	if(uv.size() != 8):
		print("Error: not a Valve-format UV array")
		return null

	var uv_out = Vector2.ZERO

	var u_axis = Vector3(uv[1], uv[2], uv[0])
	var u_shift = uv[3]
	var v_axis = Vector3(uv[5], uv[6], uv[4])
	var v_shift = uv[7]

	uv_out.x = u_axis.dot(global_vertex)
	uv_out.y = v_axis.dot(global_vertex)

	uv_out /= texture_size
	uv_out /= scale
	uv_out += Vector2(u_shift, v_shift) / texture_size

	return uv_out

func get_tangent():
	if(uv.size() == 2):
		return get_standard_tangent()
	elif(uv.size() == 8):
		return get_valve_tangent()
	else:
		print('Error: Unknown UV format')
		return null

func get_standard_tangent():
	var du = normal.dot(Vector3.UP)
	var dr = normal.dot(Vector3.RIGHT)
	var df = normal.dot(Vector3.BACK)

	var dua = abs(du)
	var dra = abs(dr)
	var dfa = abs(df)

	var u_axis: Vector3 = Vector3.ZERO
	var v_sign: float = 0

	if(dua >= dra && dua >= dfa):
		u_axis = Vector3.BACK
		v_sign = sign(du)
	elif(dra >= dua && dra >= dfa):
		u_axis = Vector3.BACK
		v_sign = -sign(dr)
	elif(dfa >= dua && dfa >= dra):
		u_axis = Vector3.RIGHT
		v_sign = sign(df)

	v_sign *= sign(scale.y)
	u_axis = u_axis.rotated(normal, deg2rad(-rotation * v_sign))

	return Plane(u_axis, v_sign)

func get_valve_tangent():
	if(uv.size() != 8):
		print("Error: not a Valve-format UV array")
		return null

	var uv_out = Vector2.ZERO

	var u_axis = Vector3(uv[1], uv[2], uv[0]).normalized()
	var v_axis = Vector3(uv[5], uv[6], uv[4]).normalized()

	var v_sign = -sign(normal.cross(u_axis).dot(v_axis))

	return Plane(u_axis, v_sign)
