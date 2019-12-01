class_name QuakePlane
extends Resource

# Resource representation of a .map file brush plane

export(PoolVector3Array) var points = [Vector3.ZERO, Vector3.RIGHT, Vector3.DOWN]
export(String) var texture
export(Vector2) var uv
export(float) var rotation
export(Vector2) var scale

func _init(points: PoolVector3Array, texture: String, uv: Vector2, rotation: float, scale: Vector2):
	self.points = points
	self.texture = texture
	self.uv = uv
	self.rotation = rotation
	self.scale = scale

# Get the plane's normal
static func get_normal(plane) -> Vector3:
	var v0 = (plane.points[2] - plane.points[0]).normalized()
	var v1 = (plane.points[1] - plane.points[0]).normalized()
	return v0.cross(v1).normalized()

# Get the plane's distance from the world origin
static func get_distance(plane) -> float:
	var normal = get_normal(plane)
	return plane.points[0].dot(normal)

# Intersect three brush planes to form a vertex
static func intersect_planes(plane1, plane2, plane3, epsilon: float = 0.0001):
	var n1 = get_normal(plane1)
	var d1 = get_distance(plane1)
	var n2 = get_normal(plane2)
	var d2 = get_distance(plane2)
	var n3 = get_normal(plane3)
	var d3 = get_distance(plane3)

	var m1 = Vector3(n1.x, n2.x, n3.x)
	var m2 = Vector3(n1.y, n2.y, n3.y)
	var m3 = Vector3(n1.z, n2.z, n3.z)
	var d = Vector3(d1, d2, d3)

	var u = m2.cross(m3)
	var v = m1.cross(d)

	var denom = m1.dot(u)

	if(abs(denom) < epsilon):
		return null

	return Vector3(d.dot(u) / denom, m3.dot(v) / denom, -m2.dot(v) / denom)
