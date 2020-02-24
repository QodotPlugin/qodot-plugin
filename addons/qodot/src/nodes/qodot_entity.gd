class_name QodotEntity
extends QodotSpatial

export(Dictionary) var properties setget set_properties

func set_properties(new_properties : Dictionary) -> void:
	if(properties != new_properties):
		properties = new_properties
		update_properties()

func update_properties() -> void:
	pass

func get_class() -> String:
	return 'QodotEntity'
