class_name QodotEntity
extends QodotSpatial

@export var properties: Dictionary :
	get:
		return properties # TODOConverter40 Non existent get function 
	set(new_properties):
		if(properties != new_properties):
			properties = new_properties
			update_properties()

func update_properties() -> void:
	pass

func get_class() -> String:
	return 'QodotEntity'
