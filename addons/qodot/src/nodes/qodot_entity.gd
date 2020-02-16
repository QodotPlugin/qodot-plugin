class_name QodotEntity
extends QodotSpatial

export(Dictionary) var properties setget set_properties

func set_properties(new_properties):
	if(properties != new_properties):
		properties = new_properties
		update_properties()

func update_properties():
	pass

func get_class():
	return 'QodotEntity'
