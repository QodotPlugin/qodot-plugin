class_name QodotBuildCollision
extends QodotBuildStep

func should_spawn_brush_collision(entity_properties: Dictionary) -> bool:
	if('classname' in entity_properties):
		return entity_properties['classname'] != 'func_illusionary'

	return true

func get_brush_collision_vertices(
	entity_properties: Dictionary,
	brush: QuakeBrush,
	world_space: bool = false
	) -> PoolVector3Array:
	var collision_vertices = PoolVector3Array()

	for face in brush.faces:
		for vertex in face.face_vertices:

			var vertex_present = false
			for collision_vertex in collision_vertices:
				if((vertex - collision_vertex).length() < 0.001):
					vertex_present = true

			if not vertex_present:
				if(world_space):
					collision_vertices.append(vertex + face.center - brush.center)
				else:
					collision_vertices.append(vertex + face.center - brush.center)

	return collision_vertices

func get_brush_collision_triangles(brush: QuakeBrush, global_space: bool = false) -> PoolVector3Array:
	var collision_triangles = PoolVector3Array()

	for face in brush.faces:
		var face_triangles = face.get_triangles(global_space)
		for triangle_vertex in face_triangles:
			collision_triangles.append(triangle_vertex)

	return collision_triangles

# Create and return a CollisionObject for the given .map classname
func spawn_brush_collision_object(entity_properties: Dictionary) -> CollisionObject:
	var node = null

	# Use an Area for trigger brushes
	if('classname' in entity_properties):
		if(entity_properties['classname'].find('trigger') > -1):
			return Area.new()

	return StaticBody.new()

func has_static_collision(entity_properties):
	if not 'classname' in entity_properties:
		return false

	if entity_properties['classname'].find('trigger') != -1:
		return false

	if entity_properties['classname'] == 'func_illusionary':
		return false

	return true

func has_area_collision(entity_properties):
	if not 'classname' in entity_properties:
		return false

	if entity_properties['classname'].find('trigger') != -1:
		return true

	return false
