class_name QuakeFace

# Resource representation of a .map file brush plane

var vertices: PoolVector3Array
var plane: Plane
var texture: String
var uv: PoolRealArray
var rotation: float
var scale: Vector2
var surface: int
var content: int
var color: int
var hexen_2_param: int

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
	self.plane = Plane(vertices[0], vertices[1], vertices[2])

	self.texture = texture
	self.uv = uv
	self.rotation = rotation
	self.scale = scale
	self.surface = surface
	self.content = content
	self.color = color
	self.hexen_2_param = hexen_2_param

# Get the plane's normal
func get_normal() -> Vector3:
	return self.plane.normal

# Get the plane's distance from the world origin
func get_distance() -> float:
	return self.plane.d

# Intersect three brush planes to form a vertex
func intersect_faces(face2, face3):
	return self.plane.intersect_3(face2.plane, face3.plane)
