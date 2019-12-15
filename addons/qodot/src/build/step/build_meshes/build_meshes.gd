class_name QodotBuildMeshes
extends QodotBuildStep

# Determine whether the given brush should create a set of visual face meshes
static func should_spawn_brush_mesh(entity_properties: Dictionary, brush: QuakeBrush) -> bool:
	# Don't spawn collision if the brush is textured entirely with CLIP
	var is_clip = false
	for face in brush.faces:
		if(face.texture.findn('clip') != -1):
			is_clip = true
			break

	if(is_clip):
		return false

	# Classname-specific behavior
	if('classname' in entity_properties):
		# Don't spawn collision for trigger brushes
		return entity_properties['classname'].findn('trigger') == -1

	# Default to true for entities with empty classnames
	return true

# Determine whether the given face should spawn a visual mesh
static func should_spawn_face_mesh(entity_properties: Dictionary, brush: QuakeBrush, face: QuakeFace) -> bool:
	# Don't spawn a mesh if the face is textured with SKIP
	if(face.texture.findn('skip') > -1):
		return false

	return true

static func get_face_mesh(surface_tool: SurfaceTool, center: Vector3, face: QuakeFace, texture_size: Vector2, color: Color, inverse_scale_factor: float, global_space: bool):
	var vertices = PoolVector3Array()
	var uvs = PoolVector2Array()
	var colors = PoolColorArray()
	var uv2s = PoolVector2Array()
	var normals = PoolVector3Array()
	var tangents = []

	for vertex in face.face_vertices:

		var global_vertex = (vertex + face.center)

		if(global_space):
			vertices.append(global_vertex)
		else:
			vertices.append(vertex)

		var uv = get_uv(face, global_vertex, texture_size, inverse_scale_factor)
		if uv:
			uvs.append(uv)
			uv2s.append(uv)
		else:
			uvs.append(Vector2.ZERO)
			uv2s.append(Vector2.ZERO)

		colors.append(color)

		normals.append(face.normal)

		var tangent = get_tangent(face)
		tangents.append(tangent)

	surface_tool.add_triangle_fan(vertices, uvs, colors, uv2s, normals, tangents)

static func get_uv(face: QuakeFace, vertex: Vector3, texture_size: Vector2, inverse_scale_factor: float):
	if(face.uv.size() == 2):
		return get_standard_uv(
				vertex,
				face.normal,
				texture_size,
				face.uv,
				face.rotation,
				face.scale,
				inverse_scale_factor
			)
	elif(face.uv.size() == 8):
		return get_valve_uv(
				vertex,
				face.normal,
				texture_size,
				face.uv,
				face.rotation,
				face.scale,
				inverse_scale_factor
			)
	else:
		print('Error: Unknown UV format')
		return null

static func get_standard_uv(
	global_vertex: Vector3,
	normal: Vector3,
	texture_size: Vector2,
	uv: PoolRealArray,
	rotation: float,
	scale: Vector2,
	inverse_scale_factor: float):
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
	uv_out /=  texture_size / inverse_scale_factor
	uv_out /= scale
	uv_out += Vector2(uv[0], uv[1]) / texture_size

	return uv_out


static func get_valve_uv(
	global_vertex: Vector3,
	normal: Vector3,
	texture_size: Vector2,
	uv: PoolRealArray,
	rotation: float,
	scale: Vector2,
	inverse_scale_factor: float):
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

	uv_out /= texture_size / inverse_scale_factor
	uv_out /= scale
	uv_out += Vector2(u_shift, v_shift) / texture_size

	return uv_out

static func get_tangent(face: QuakeFace):
	if(face.uv.size() == 2):
		return get_standard_tangent(
				face.normal,
				face.rotation,
				face.scale
			)
	elif(face.uv.size() == 8):
		return get_valve_tangent(
				face.normal,
				face.uv,
				face.rotation,
				face.scale
			)
	else:
		print('Error: Unknown UV format')
		return null

static func get_standard_tangent(
		normal: Vector3,
		rotation: float,
		scale: Vector2
	):
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

static func get_valve_tangent(
	normal: Vector3,
	uv: PoolRealArray,
	rotation: float,
	scale: Vector2
	):
	if(uv.size() != 8):
		print("Error: not a Valve-format UV array")
		return null

	var uv_out = Vector2.ZERO

	var u_axis = Vector3(uv[1], uv[2], uv[0]).normalized()
	var v_axis = Vector3(uv[5], uv[6], uv[4]).normalized()

	var v_sign = -sign(normal.cross(u_axis).dot(v_axis))

	return Plane(u_axis, v_sign)
