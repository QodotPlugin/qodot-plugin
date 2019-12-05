class_name QodotBrushMapper

# Determine whether the given brush should create a set of visual face meshes
static func should_spawn_brush_mesh(entity: QuakeEntity, brush: QuakeBrush) -> bool:
	# Don't spawn collision if the brush is textured entirely with CLIP
	var is_clip = true
	for face in brush.faces:
		if(face.texture.find('clip') == -1):
			is_clip = false

	if(is_clip):
		return false

	# Classname-specific behavior
	if('classname' in entity.properties):
		# Don't spawn collision for trigger brushes
		return entity.properties['classname'].find('trigger') == -1

	# Default to true for entities with empty classnames
	return true

static func create_brush_meshes(entity: QuakeEntity, brush: QuakeBrush, face_mapper, texture_mapper, base_texture_path, material_extension, texture_extension, default_material, inverse_scale_factor) -> Array:
	var brush_meshes = []

	for face in brush.faces:
		var spatial_material = texture_mapper.get_spatial_material(face, base_texture_path, material_extension, texture_extension, default_material)
		if(face_mapper.should_spawn_face_mesh(entity, brush, face)):
			var face_mesh_node = face_mapper.spawn_face_mesh(brush, face, texture_mapper, base_texture_path, material_extension, texture_extension, default_material, inverse_scale_factor)
			brush_meshes.append(face_mesh_node)

	return brush_meshes

# Determine whether the given .map classname should create a collision object
static func should_spawn_brush_collision(entity: QuakeEntity, brush: QuakeBrush) -> bool:
	return true

static func create_brush_collision_objects(entity: QuakeEntity, brush: QuakeBrush, inverse_scale_factor: float) -> Array:
	var collision_vertices = get_brush_collision_vertices(entity, brush)

	var scaled_collision_vertices = PoolVector3Array()
	for collision_vertex in collision_vertices:
		scaled_collision_vertices.append(collision_vertex / inverse_scale_factor)

	var brush_collision_shape = spawn_brush_collision_shape(entity, brush, scaled_collision_vertices)

	var brush_collision_object = spawn_brush_collision_object(entity, brush)
	brush_collision_object.add_child(brush_collision_shape)

	return [brush_collision_object]

# Create and return a CollisionObject for the given .map classname
static func spawn_brush_collision_object(entity: QuakeEntity, brush: QuakeBrush) -> CollisionObject:
	var node = null

	# Use an Area for trigger brushes
	if('classname' in entity.properties):
		if(entity.properties['classname'].find('trigger') > -1):
			return Area.new()

	return StaticBody.new()

static func spawn_brush_collision_shape(entity: QuakeEntity, brush: QuakeBrush, vertices: PoolVector3Array) -> CollisionShape:
	var brush_convex_collision = ConvexPolygonShape.new()
	brush_convex_collision.set_points(vertices)

	var brush_collision_shape = CollisionShape.new()
	brush_collision_shape.set_shape(brush_convex_collision)

	return brush_collision_shape

static func get_brush_collision_vertices(entity: QuakeEntity, brush: QuakeBrush):
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
