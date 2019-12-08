class_name QodotBuildBrushCollision
extends QodotBuildStep

func get_name() -> String:
	return "brush_collision"

func get_type() -> int:
	return self.Type.PER_BRUSH

func get_build_params() -> Array:
	return ['inverse_scale_factor']

func get_finalize_params() -> Array:
	return ['brush_collision']

func _run(context) -> Array:
	var entity_idx = context['entity_idx']
	var brush_idx = context['brush_idx']
	var entity_properties = context['entity_properties']
	var brush_data = context['brush_data']
	var inverse_scale_factor = context['inverse_scale_factor']

	var map_reader = QuakeMapReader.new()
	var brush = map_reader.create_brush(brush_data)

	var collision_vertices = get_brush_collision_vertices(entity_properties, brush)
	var scaled_collision_vertices = PoolVector3Array()
	for collision_vertex in collision_vertices:
		scaled_collision_vertices.append(collision_vertex / inverse_scale_factor)

	return ["nodes", [entity_idx, brush_idx], [], entity_properties, scaled_collision_vertices]

func wants_finalize():
	return true

func _finalize(context) -> void:
	var brush_collision = context['brush_collision']

	for brush_collision_idx in range(0, brush_collision.size()):
		var brush_collision_data = brush_collision[brush_collision_idx]

		var entity_properties = brush_collision_data[3]
		var brush_collision_vertices = brush_collision_data[4]

		var brush_collision_object = spawn_brush_collision_object(entity_properties)

		var brush_convex_collision = ConvexPolygonShape.new()
		brush_convex_collision.set_points(brush_collision_vertices)

		var brush_collision_shape = CollisionShape.new()
		brush_collision_shape.set_shape(brush_convex_collision)

		brush_collision_object.add_child(brush_collision_shape)

		brush_collision[brush_collision_idx][2] = [brush_collision_object]

func should_spawn_brush_collision(entity_properties: Dictionary) -> bool:
	if('classname' in entity_properties):
		return entity_properties['classname'] != 'func_illusionary'

	return true

static func get_brush_collision_vertices(entity_properties: Dictionary, brush: QuakeBrush):
	var collision_vertices = PoolVector3Array()

	for face in brush.faces:
		for vertex in face.face_vertices:

			var vertex_present = false
			for collision_vertex in collision_vertices:
				if((vertex - collision_vertex).length() < 0.001):
					vertex_present = true

			if not vertex_present:
				collision_vertices.append(vertex + face.center - brush.center)

	return collision_vertices

# Create and return a CollisionObject for the given .map classname
static func spawn_brush_collision_object(entity_properties: Dictionary) -> CollisionObject:
	var node = null

	# Use an Area for trigger brushes
	if('classname' in entity_properties):
		if(entity_properties['classname'].find('trigger') > -1):
			return Area.new()

	return StaticBody.new()
