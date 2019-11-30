class_name QuakeBrush
extends Resource

export(Array) var planes = []

func _init(planes):
	self.planes = planes

static func point_in_hull(planes: Array, point: Vector3, epsilon = 0.0001):
	for plane in planes:
		var plane_normal = QuakePlane.get_normal(plane)
		var dist = point.dot(plane_normal) - QuakePlane.get_distance(plane)
		if(dist > epsilon):
			return false
	
	return true
