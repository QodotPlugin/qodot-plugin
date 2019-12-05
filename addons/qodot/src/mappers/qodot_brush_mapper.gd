class_name QodotBrushMapper

# Determine whether the given brush should create a set of visual face meshes
static func should_spawn_brush_mesh(brush: QuakeBrush, parent_entity: QuakeEntity) -> bool:
	# Don't spawn collision if the brush is textured entirely with CLIP
	var is_clip = true
	for face in brush.faces:
		if(face.texture.find('clip') == -1):
			is_clip = false

	if(is_clip):
		return false

	# Classname-specific behavior
	if('classname' in parent_entity.properties):
		# Don't spawn collision for trigger brushes
		return parent_entity.properties['classname'].find('trigger') == -1

	# Default to true for entities with empty classnames
	return true

# Determine whether the given .map classname should create a collision object
static func should_spawn_brush_collision(brush: QuakeBrush, parent_entity: QuakeEntity) -> bool:
	return true

# Create and return a CollisionObject for the given .map classname
static func spawn_brush_collision_object(brush: QuakeBrush, parent_entity: QuakeEntity) -> CollisionObject:
	var node = null

	# Use an Area for trigger brushes
	if('classname' in parent_entity.properties):
		if(parent_entity.properties['classname'].find('trigger') > -1):
			return Area.new()

	return StaticBody.new()

static func spawn_brush_collision_shape(sorted_local_face_vertices: Dictionary, brush_center: Vector3, brush: QuakeBrush, parent_entity: QuakeEntity) -> CollisionShape:
	var collision_vertices = []

	for plane_idx in sorted_local_face_vertices:
		var vertices = sorted_local_face_vertices[plane_idx]
		for vertex in vertices:

			var vertex_present = false
			for collision_vertex in collision_vertices:
				if((vertex - collision_vertex).length() < 0.001):
					vertex_present = true

			if(!vertex_present):
				collision_vertices.append(vertex - brush_center)

	var brush_convex_collision = ConvexPolygonShape.new()
	brush_convex_collision.set_points(collision_vertices)

	var brush_collision_shape = CollisionShape.new()
	brush_collision_shape.set_shape(brush_convex_collision)

	return brush_collision_shape
