class_name QuakeEntity
extends Resource

export(Dictionary) var properties
export(Array) var brushes = []

func _init(properties, brushes):
	self.properties = properties
	self.brushes = brushes
