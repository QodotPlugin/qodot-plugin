class_name QodotBuildAreaCollisionShapes
extends QodotBuildCollision

func get_name() -> String:
	return "area_collision_shapes"

func get_type() -> int:
	return self.Type.PER_BRUSH

func get_finalize_params() -> Array:
	return ['area_collision_shapes']

func get_wants_finalize():
	return true

func _run(context) -> Dictionary:
	var entity_idx = context['entity_idx']
	var brush_idx = context['brush_idx']
	var entity_properties = context['entity_properties']
	var brush_data = context['brush_data']

	if not has_area_collision(entity_properties):
		return {}

	var brush = create_brush_from_face_data(brush_data)

	var collision_vertices = get_brush_collision_vertices(entity_properties, brush, true)
	var scaled_collision_vertices = PoolVector3Array()
	for collision_vertex in collision_vertices:
		scaled_collision_vertices.append(collision_vertex)

	return {
		'area_collision_shapes': {
			get_entity_brush_key(entity_idx, brush_idx): {
				'brush_center': brush.center,
				'brush_collision_vertices': scaled_collision_vertices
			}
		}
	}


func _finalize(context) -> Dictionary:
	var area_collision_shapes = context['area_collision_shapes']

	var collision_shape_dict = {}

	for area_collision_shape_key in area_collision_shapes:
		var brush_center = area_collision_shapes[area_collision_shape_key]['brush_center']
		var brush_collision_vertices = area_collision_shapes[area_collision_shape_key]['brush_collision_vertices']

		var brush_convex_collision = ConvexPolygonShape.new()
		brush_convex_collision.set_points(brush_collision_vertices)

		var brush_collision_shape = CollisionShape.new()
		brush_collision_shape.set_shape(brush_convex_collision)

		var brush_area = Area.new()
		brush_area.name = area_collision_shape_key + "_Trigger"
		brush_area.translation = brush_center
		brush_area.add_child(brush_collision_shape)

		collision_shape_dict[area_collision_shape_key] = brush_area

	return {
		'nodes': {
			'collision': collision_shape_dict
		}
	}
