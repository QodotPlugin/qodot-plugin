class_name QodotBuildStaticCollisionShapes
extends QodotBuildCollision

func get_name() -> String:
	return "static_collision_shapes"

func get_type() -> int:
	return self.Type.PER_BRUSH

func get_build_params() -> Array:
	return ['inverse_scale_factor']

func get_finalize_params() -> Array:
	return ['static_collision_shapes', 'inverse_scale_factor']

func get_wants_finalize():
	return true

func _run(context):
	var entity_idx = context['entity_idx']
	var brush_idx = context['brush_idx']
	var entity_properties = context['entity_properties']
	var brush_data = context['brush_data']
	var inverse_scale_factor = context['inverse_scale_factor']

	if not has_static_collision(entity_properties):
		return null

	var map_reader = QuakeMapReader.new()
	var brush = map_reader.create_brush(brush_data)

	var collision_vertices = get_brush_collision_vertices(entity_properties, brush, true)
	var scaled_collision_vertices = PoolVector3Array()
	for collision_vertex in collision_vertices:
		scaled_collision_vertices.append(collision_vertex / inverse_scale_factor)

	return ["nodes", NodePath("./Collision/StaticBody"), [], brush_idx, brush.center, scaled_collision_vertices]

func _finalize(context) -> void:
	var static_collision_shapes = context['static_collision_shapes']
	var inverse_scale_factor = context['inverse_scale_factor']

	for brush_collision_idx in range(0, static_collision_shapes.size()):
		var brush_collision_data = static_collision_shapes[brush_collision_idx]

		var brush_idx = brush_collision_data[3]
		var brush_center = brush_collision_data[4]
		var brush_collision_vertices = brush_collision_data[5]

		var brush_convex_collision = ConvexPolygonShape.new()
		brush_convex_collision.set_points(brush_collision_vertices)

		var brush_collision_shape = CollisionShape.new()
		brush_collision_shape.translation = brush_center / inverse_scale_factor
		brush_collision_shape.set_shape(brush_convex_collision)

		static_collision_shapes[brush_collision_idx][2] = [brush_collision_shape]
