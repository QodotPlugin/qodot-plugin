class_name QuakeEntity

# Resource representation of a .map file entity

var properties = {}
var brushes = []

func _init(properties, brushes):
	self.properties = properties
	self.brushes = brushes
