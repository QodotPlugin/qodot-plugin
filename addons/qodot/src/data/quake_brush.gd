class_name QuakeBrush

# Resource representation of a .map file brush

var faces = []
var center = Vector3.ZERO

func _init(faces):
	self.faces = faces

	center = Vector3.ZERO
	var vertex_count = 0
	for face in self.faces:
		center += face.plane.center()
	center /= self.faces.size()

# Check to see if a given vertex resides inside a set of brush faces
func vertex_in_hull(vertex: Vector3):
	for face in self.faces:
		if(face.plane.is_point_over(vertex) && face.plane.distance_to(vertex) > 0.001):
			return false

	return true
