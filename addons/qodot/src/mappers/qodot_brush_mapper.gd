class_name QodotBrushMapper

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

static func create_brush_meshes(entity_properties: Dictionary, brush: QuakeBrush, face_mapper, texture_mapper, base_texture_path, material_extension, texture_extension, default_material, inverse_scale_factor) -> Array:
	var brush_meshes = []

	for face in brush.faces:
		var spatial_material = texture_mapper.get_spatial_material(face, base_texture_path, material_extension, texture_extension, default_material)
		if(face_mapper.should_spawn_face_mesh(entity_properties, brush, face)):
			var face_mesh_node = face_mapper.spawn_face_mesh(brush, face, texture_mapper, base_texture_path, material_extension, texture_extension, default_material, inverse_scale_factor)
			brush_meshes.append(face_mesh_node)

	return brush_meshes

# Determine whether the given .map classname should create a collision object
static func should_spawn_brush_collision(entity_properties: Dictionary, brush: QuakeBrush) -> bool:
	if('classname' in entity_properties):
		return entity_properties['classname'] != 'func_illusionary'

	return true

static func create_brush_collision_objects(entity_properties: Dictionary, brush: QuakeBrush, inverse_scale_factor: float) -> Array:
	var collision_vertices = get_brush_collision_vertices(entity_properties, brush)

	var scaled_collision_vertices = PoolVector3Array()
	for collision_vertex in collision_vertices:
		scaled_collision_vertices.append(collision_vertex / inverse_scale_factor)

	var brush_collision_shape = spawn_brush_collision_shape(entity_properties, brush, scaled_collision_vertices)

	var brush_collision_object = spawn_brush_collision_object(entity_properties, brush)
	brush_collision_object.add_child(brush_collision_shape)

	return [brush_collision_object]

# Create and return a CollisionObject for the given .map classname
static func spawn_brush_collision_object(entity_properties: Dictionary, brush: QuakeBrush) -> CollisionObject:
	var node = null

	# Use an Area for trigger brushes
	if('classname' in entity_properties):
		if(entity_properties['classname'].find('trigger') > -1):
			return Area.new()

	return StaticBody.new()

static func spawn_brush_collision_shape(entity_properties: Dictionary, brush: QuakeBrush, vertices: PoolVector3Array) -> CollisionShape:
	var brush_convex_collision = ConvexPolygonShape.new()
	brush_convex_collision.set_points(vertices)

	var brush_collision_shape = CollisionShape.new()
	brush_collision_shape.set_shape(brush_convex_collision)

	return brush_collision_shape

static func get_brush_collision_vertices(entity_properties: Dictionary, brush: QuakeBrush):
	var collision_vertices = []

	for face in brush.faces:
		for vertex in face.face_vertices:

			var vertex_present = false
			for collision_vertex in collision_vertices:
				if((vertex - collision_vertex).length() < 0.001):
					vertex_present = true

			if not vertex_present:
				collision_vertices.append(vertex + face.center - brush.center)

	return collision_vertices

static func create_brush_face_axes(brush: QuakeBrush, inverse_scale_factor: float):
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

static func create_brush_face_vertices(brush: QuakeBrush, inverse_scale_factor: float):
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
