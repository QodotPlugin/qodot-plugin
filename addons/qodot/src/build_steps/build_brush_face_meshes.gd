class_name QodotBuildBrushFaceMeshes
extends QodotBuildStep

func get_name() -> String:
	return "brush_face_meshes"

func get_type() -> int:
	return self.Type.PER_BRUSH

func get_build_params() -> Array:
	return ['material_dict', 'inverse_scale_factor']

func get_finalize_params() -> Array:
	return ['brush_face_meshes', 'material_dict', 'inverse_scale_factor']

func _run(context) -> Array:
	var entity_idx = context['entity_idx']
	var brush_idx = context['brush_idx']
	var entity_properties = context['entity_properties']
	var brush_data = context['brush_data']
	var material_dict = context['material_dict']
	var inverse_scale_factor = context['inverse_scale_factor']

	var map_reader = QuakeMapReader.new()
	var brush = map_reader.create_brush(brush_data)

	if not should_spawn_brush_mesh(entity_properties, brush):
		return ["nodes", [entity_idx, brush_idx], [], [], []]

	var face_nodes = []
	var face_indices = []

	for face_idx in range(0, brush.faces.size()):
		var face = brush.faces[face_idx]
		if(should_spawn_face_mesh(entity_properties, brush, face)):
			var face_mesh_node = MeshInstance.new()
			face_mesh_node.name = 'Face0'
			face_nodes.append(face_mesh_node)
			face_indices.append(face_idx)

	return ["nodes", [entity_idx, brush_idx], face_nodes, face_indices, brush_data]

func wants_finalize():
	return true

func _finalize(context):
	var brush_face_meshes = context['brush_face_meshes']
	var material_dict = context['material_dict']
	var inverse_scale_factor = context['inverse_scale_factor']

	for brush_face_mesh in brush_face_meshes:
		var face_nodes = brush_face_mesh[2]
		var face_indices = brush_face_mesh[3]
		var brush_data = brush_face_mesh[4]

		var map_reader = QuakeMapReader.new()
		var brush = map_reader.create_brush(brush_data)

		for face_idx in range(0, face_nodes.size()):
			var face_node = face_nodes[face_idx]
			var brush_face_idx = face_indices[face_idx]
			if(face_node):
				var face = brush.faces[brush_face_idx]
				var mesh = get_face_mesh(brush.center, face, material_dict, inverse_scale_factor)
				face_node.translation = (face.center - brush.center) / inverse_scale_factor
				face_node.set_mesh(mesh)

# Determine whether the given brush should create a set of visual face meshes
static func should_spawn_brush_mesh(entity_properties: Dictionary, brush: QuakeBrush) -> bool:
	# Don't spawn collision if the brush is textured entirely with CLIP
	var is_clip = true
	for face in brush.faces:
		if(face.texture.find('clip') == -1):
			is_clip = false

	if(is_clip):
		return false

	# Classname-specific behavior
	if('classname' in entity_properties):
		# Don't spawn collision for trigger brushes
		return entity_properties['classname'].find('trigger') == -1

	# Default to true for entities with empty classnames
	return true

# Determine whether the given face should spawn a visual mesh
static func should_spawn_face_mesh(entity_properties: Dictionary, brush: QuakeBrush, face: QuakeFace) -> bool:
	# Don't spawn a mesh if the face is textured with SKIP
	if(face.texture.find('skip') > -1):
		return false

	return true

static func get_face_mesh(center: Vector3, face: QuakeFace, material_dict: Dictionary, inverse_scale_factor: float):
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLE_FAN)

	surface_tool.add_normal(face.normal)
	surface_tool.add_tangent(face.tangent)

	var spatial_material = material_dict[face.texture]
	surface_tool.set_material(spatial_material)

	var vertex_idx = 0
	for vertex in face.face_vertices:
		var global_vertex = (vertex + center) / inverse_scale_factor

		var uv = get_uv(face, global_vertex, spatial_material, inverse_scale_factor)
		if uv:
			surface_tool.add_uv(uv)

		surface_tool.add_index(vertex_idx)
		surface_tool.add_vertex(vertex / inverse_scale_factor)
		vertex_idx += 1

	return surface_tool.commit()

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
