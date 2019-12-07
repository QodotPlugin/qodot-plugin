class_name QodotFaceMapper

# Determine whether the given face should spawn a visual mesh
static func should_spawn_face_mesh(entity: QuakeEntity, brush: QuakeBrush, face: QuakeFace) -> bool:
	# Don't spawn a mesh if the face is textured with SKIP
	if(face.texture.find('skip') > -1):
		return false

	return true

static func spawn_face_mesh(brush: QuakeBrush, face: QuakeFace, texture_mapper: QodotTextureLoader, base_texture_path, material_extension, texture_extension, default_material, inverse_scale_factor):
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLE_FAN)

	surface_tool.add_normal(face.normal)
	surface_tool.add_tangent(face.tangent)

	var spatial_material = texture_mapper.get_spatial_material(face.texture, base_texture_path, material_extension, texture_extension, default_material)
	surface_tool.set_material(spatial_material)

	var vertex_idx = 0
	for vertex in face.face_vertices:
		var global_vertex = (vertex + brush.center) / inverse_scale_factor

		var uv = get_uv(face, global_vertex, spatial_material, inverse_scale_factor)
		if uv:
			surface_tool.add_uv(uv)

		surface_tool.add_index(vertex_idx)
		surface_tool.add_vertex(vertex / inverse_scale_factor)
		vertex_idx += 1

	var face_mesh_node = MeshInstance.new()
	face_mesh_node.name = 'Face0'
	face_mesh_node.translation = (face.center - brush.center) / inverse_scale_factor

	face_mesh_node.set_mesh(surface_tool.commit())

	return face_mesh_node

static func get_uv(face: QuakeFace, vertex: Vector3, spatial_material: SpatialMaterial, inverse_scale_factor: float):
	if spatial_material:
		var texture = spatial_material.get_texture(SpatialMaterial.TEXTURE_ALBEDO)
		if texture:
			if(face.uv.size() == 2):
				return get_standard_uv(
						vertex,
						face.normal,
						texture,
						face.uv,
						face.rotation,
						face.scale,
						inverse_scale_factor
					)
			elif(face.uv.size() == 8):
				return get_valve_uv(
						vertex,
						face.normal,
						texture,
						face.uv,
						face.rotation,
						face.scale,
						inverse_scale_factor
					)
			else:
				print('Error: Unknown UV format')
				return null

	return null

static func get_standard_uv(
	global_vertex: Vector3,
	normal: Vector3,
	texture: Texture,
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

	uv_out /=  texture.get_size() / inverse_scale_factor

	uv_out = uv_out.rotated(deg2rad(rotation))
	uv_out /= scale
	uv_out += Vector2(uv[0], uv[1]) / texture.get_size()

	return uv_out


static func get_valve_uv(
	global_vertex: Vector3,
	normal: Vector3,
	texture: Texture,
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

	var texture_size = texture.get_size()

	uv_out /= texture_size / inverse_scale_factor
	uv_out /= scale
	uv_out += Vector2(u_shift, v_shift) / texture_size

	return uv_out

