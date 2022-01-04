class_name LiquidLayer
extends Area3D

@export var buoyancy_factor: float = 10.0
@export var lateral_damping_factor: float = 0.0
@export var vertical_damping_factor: float = 0.0

var buoyancy_dict := {}

func _init():
	connect("body_shape_entered",Callable(self,"body_shape_entered"))
	connect("body_shape_exited",Callable(self,"body_shape_exited"))

func body_shape_entered(body_id, body: Node, body_shape_idx: int, self_shape_idx: int) -> void:
	if not body is RigidDynamicBody3D:
		return

	var self_collision_shape = shape_owner_get_owner(shape_find_owner(self_shape_idx))
	var body_collision_shape = body.shape_owner_get_owner(body.shape_find_owner(body_shape_idx))

	var self_shape = self_collision_shape.get_shape()
	var body_shape = body_collision_shape.get_shape()

	var self_aabb = create_shape_aabb(self_shape)
	var body_aabb = create_shape_aabb(body_shape)

	buoyancy_dict[body] = {
		'entry_point': body.global_transform.origin,
		'self_aabb': self_aabb,
		'body_aabb': body_aabb
	}

func body_shape_exited(body_id, body: Node, body_shape_idx: int, self_shape_idx: int) -> void:
	if body in buoyancy_dict:
		buoyancy_dict.erase(body)

func create_shape_aabb(shape: Shape3D) -> AABB:
	if shape is ConvexPolygonShape3D:
		return create_convex_aabb(shape)
	elif shape is SphereShape3D:
		return create_sphere_aabb(shape)

	return AABB()

func create_convex_aabb(convex_shape: ConvexPolygonShape3D) -> AABB:
	var points = convex_shape.get_points()
	var aabb = null

	for point in points:
		if not aabb:
			aabb = AABB(point, Vector3.ZERO)
		else:
			aabb = aabb.expand(point)

	return aabb

func create_sphere_aabb(sphere_shape: SphereShape3D) -> AABB:
	return AABB(-Vector3.ONE * sphere_shape.radius, Vector3.ONE * sphere_shape.radius)

func _physics_process(delta: float) -> void:
	for body in buoyancy_dict:
		var buoyancy_data = buoyancy_dict[body]

		var self_aabb = buoyancy_data['self_aabb']
		self_aabb.position += global_transform.origin

		var body_aabb = buoyancy_data['body_aabb']
		body_aabb.position += body.global_transform.origin

		var displacement = self_aabb.end.y - body_aabb.position.y
		body.add_central_force(Vector3.UP * displacement * buoyancy_factor)
		body.add_central_force(Vector3(1, 0, 1) * body.get_linear_velocity() * displacement * -lateral_damping_factor)
		body.add_central_force(Vector3(0, 1, 0) * body.get_linear_velocity() * -vertical_damping_factor)
