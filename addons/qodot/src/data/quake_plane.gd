class_name QuakePlane

# Resource representation of a .map file brush plane

var vertices = [Vector3.ZERO, Vector3.RIGHT, Vector3.DOWN]
var texture
var uv
var rotation
var scale
var surface
var content
var color
var hexen_2_param

func _init(
	vertices: PoolVector3Array,
	texture: String,
	uv: PoolRealArray,
	rotation: float,
	scale: Vector2,
	surface: int,
	content: int,
	color: int,
	hexen_2_param: int
	):
	self.vertices = vertices
	self.texture = texture
	self.uv = uv
	self.rotation = rotation
	self.scale = scale
	self.surface = surface
	self.content = content
	self.color = color
	self.hexen_2_param = hexen_2_param

# Get the plane's normal
static func get_normal(plane) -> Vector3:
	var v0 = (plane.vertices[2] - plane.vertices[0]).normalized()
	var v1 = (plane.vertices[1] - plane.vertices[0]).normalized()
	return v0.cross(v1).normalized()

# Get the plane's distance from the world origin
static func get_distance(plane) -> float:
	var normal = get_normal(plane)
	return plane.vertices[0].dot(normal)

# Intersect three brush planes to form a vertex
static func intersect_planes(plane1, plane2, plane3):
	var n1 = get_normal(plane1)
	var d1 = get_distance(plane1)
	var n2 = get_normal(plane2)
	var d2 = get_distance(plane2)
	var n3 = get_normal(plane3)
	var d3 = get_distance(plane3)

	var g_p1 = Plane(n1, d1)
	var g_p2 = Plane(n2, d2)
	var g_p3 = Plane(n3, d3)

	return g_p1.intersect_3(g_p2, g_p3)
