class_name QodotEntityProperties
extends Resource
tool

## Used to allow adding properties to exported definitions

enum PropertyType { IntegerProperty, StringProperty }
export (String) var name
export (PropertyType) var type = PropertyType.IntegerProperty
export (String) var short_description
export (String) var long_description
export (String) var default_value

func property_type_text() -> String:
	match type:
		PropertyType.IntegerProperty:
			return "integer"
		PropertyType.StringProperty:
			return "string"
		_:
			return "impossible, only to please typechecker"
func get_properties_dictionary():
	return {
		"name": name,
		"short_description": short_description,
		"long_description": long_description,
		"type_string": property_type_text(),
		"default_value": default_value,
		}
