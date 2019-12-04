class_name QuakeBrush

# Resource representation of a .map file brush

var planes = []
var center = Vector3.ZERO

func _init(planes):
	self.planes = planes

	center = Vector3.ZERO
	var vertex_count = 0
	for plane in self.planes:
		for vertex in plane.vertices:
			center += vertex
			vertex_count += 1
	center /= vertex_count

# Check to see if a given vertex resides inside a set of brush planes
static func vertex_in_hull(planes: Array, vertex: Vector3, epsilon = 0.0001):
	for plane in planes:
		var plane_normal = QuakePlane.get_normal(plane)
		var dist = vertex.dot(plane_normal) - QuakePlane.get_distance(plane)
		if(dist > epsilon):
			return false

	return true
