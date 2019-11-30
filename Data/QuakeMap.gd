class_name QuakeMap
extends Resource

# Resource representation of a .map file

export(Array) var entities = []

func _init(entities):
	self.entities = entities
