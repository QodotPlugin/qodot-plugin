class_name QodotBuildCollision
extends QodotBuildStep

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

func get_name() -> String:
	return 'collision_shapes'

func get_type() -> int:
	return self.Type.PER_BRUSH

func get_build_params():
	return ['entity_definition_set']

func _run(context) -> Dictionary:
	var entity_idx = context['entity_idx']
	var brush_idx = context['brush_idx']
	var brush_data = context['brush_data']
	var entity_definition_set = context['entity_definition_set']
	var entity_properties = context['entity_properties']

	if not should_spawn_collision_shapes(entity_definition_set, entity_properties):
		return {}

	var brush = create_brush_from_face_data(brush_data)

	return {
		get_context_key(): {
			get_entity_key(entity_idx): {
				get_brush_key(brush_idx): {
					'brush_center': brush.center,
					'brush_collision_vertices': get_brush_collision_vertices(entity_properties, brush, true)
				}
			}
		}
	}

func get_context_key() -> String:
	return 'collision_shapes'

func should_spawn_collision_shapes(entity_definition_set: Dictionary, entity_properties: Dictionary) -> bool:
	return false

func create_convex_collision_shape(vertices) -> CollisionShape:
	print("vertices: ", vertices)
	var convex_polygon = ConvexPolygonShape.new()
	convex_polygon.set_points(vertices)

	var brush_collision_shape = CollisionShape.new()
	brush_collision_shape.set_shape(convex_polygon)

	return brush_collision_shape

func create_concave_collision_shape(triangles: PoolVector3Array) -> CollisionShape:
	var concave_polygon = ConcavePolygonShape.new()
	concave_polygon.set_faces(triangles)

	var brush_collision_shape = CollisionShape.new()
	brush_collision_shape.set_shape(concave_polygon)

	return brush_collision_shape
