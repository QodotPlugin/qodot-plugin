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

# Determine whether the given .map classname should create a collision object
static func should_spawn_brush_collision(entity: QuakeEntity, brush: QuakeBrush) -> bool:
	return true

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
