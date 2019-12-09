class_name QuakeFace

# Resource representation of a .map file brush plane

var plane_vertices: PoolVector3Array
var plane: Plane
var normal: Vector3

var face_vertices = PoolVector3Array()
var center: Vector3

var texture: String

var uv: PoolRealArray
var rotation: float
var scale: Vector2

var bitmask_params: PoolIntArray

func _init(face_data: Array):
	var plane_vertices: PoolVector3Array = PoolVector3Array(face_data[0])
	var texture: String = face_data[1]
	var uv: PoolRealArray = PoolRealArray(face_data[2])
	var rotation: float = face_data[3]
	var scale: Vector2 = face_data[4]
	var bitmask_params: PoolIntArray = PoolIntArray(face_data[5])

	self.plane_vertices = plane_vertices
	self.plane = Plane(plane_vertices[0], plane_vertices[1], plane_vertices[2])
	self.normal = self.plane.normal

	self.texture = texture

	self.uv = uv
	self.rotation = rotation
	self.scale = scale
	self.bitmask_params = bitmask_params

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
