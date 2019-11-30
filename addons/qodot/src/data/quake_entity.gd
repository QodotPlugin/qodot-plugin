class_name QuakeEntity
extends Resource

# Resource representation of a .map file entity

export(Dictionary) var properties
export(Array) var brushes = []

func _init(properties, brushes):
	self.properties = properties
	self.brushes = brushes
