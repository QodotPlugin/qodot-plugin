class_name QuakeBrush
extends Resource

# Resource representation of a .map file brush

export(Array) var planes = []

func _init(planes):
	self.planes = planes

# Check to see if a given vertex resides inside a set of brush planes
static func vertex_in_hull(planes: Array, vertex: Vector3, epsilon = 0.0001):
	for plane in planes:
		var plane_normal = QuakePlane.get_normal(plane)
		var dist = vertex.dot(plane_normal) - QuakePlane.get_distance(plane)
		if(dist > epsilon):
			return false

	return true
