class_name QuakeFace

# Resource representation of a .map file brush plane

var plane_vertices: PoolVector3Array
var plane: Plane
var normal: Vector3
var tangent: Plane

var face_vertices = PoolVector3Array()
var center: Vector3

var texture: String

var uv: PoolRealArray
var rotation: float
var scale: Vector2

var surface: int
var content: int
var color: int
var hexen_2_param: int

func _init(
	plane_vertices: PoolVector3Array,
	texture: String,
	uv: PoolRealArray,
	rotation: float,
	scale: Vector2,
	surface: int,
	content: int,
	color: int,
	hexen_2_param: int
	):
	self.plane_vertices = plane_vertices
	self.plane = Plane(plane_vertices[0], plane_vertices[1], plane_vertices[2])
	self.normal = self.plane.normal

	self.texture = texture

	self.uv = uv
	self.rotation = rotation
	self.scale = scale
	self.surface = surface
	self.content = content
	self.color = color
	self.hexen_2_param = hexen_2_param

	self.tangent = self.get_tangent()

# Get the plane's normal
func get_tangent():
	if(self.uv.size() == 2):
		return self.get_standard_tangent()
	elif(self.uv.size() == 8):
		return self.get_valve_tangent()

	print("Error: Unrecognized vertex format")
	return null

# Tangent functions to work around broken auto-generated ones
# Also incorrect for now,
# but prevents materials with depth mapping from crashing the graphics driver
func get_standard_tangent() -> Plane:
	return Plane(self.normal.cross(Vector3.UP).normalized(), 0.0)

func get_valve_tangent() -> Plane:
	return Plane(self.normal.cross(Vector3.UP).normalized(), 0.0)

# Get the plane's distance from the world origin
func get_distance() -> float:
	return self.plane.d

# Intersect three brush planes to form a vertex
func intersect_faces(face2, face3):
	return self.plane.intersect_3(face2.plane, face3.plane)

func add_unique_vertex(vertex):
	if not self.has_vertex(vertex):
		self.face_vertices.append(vertex)

func has_vertex(vertex):
	for comp_vertex in self.face_vertices:
		if((comp_vertex - vertex).length() < 0.0001):
			return true

	return false

func set_center(new_center):
	self.center = new_center
