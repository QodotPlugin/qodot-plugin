tool
extends Resource
class_name TrenchBroomFaceAttribDefaults

export(String) var texture_name : String
export(Vector2) var offset : Vector2
export(Vector2) var scale : Vector2 = Vector2(1,1)
export(float) var rotation : float
export(PoolStringArray) var surface_contents : PoolStringArray
export(PoolStringArray) var surface_flags : PoolStringArray
export(float) var surface_value : float
export(Color) var color : Color

func _to_string() -> String:
	var export_object : Dictionary
	export_object["textureName"] = texture_name
	export_object["offset"] = [offset.x, offset.y]
	export_object["scale"] = [scale.x, scale.y]
	export_object["rotation"] = rotation
	if !surface_contents.empty():
		export_object["surfaceContents"] = surface_contents
	if !surface_flags.empty():
		export_object["surfaceFlags"] = surface_flags
	export_object["surfaceValue"] = surface_value
	export_object["color"] = "%f %f %f %f" % [color.r, color.g, color.b, color.a]
	
	return JSON.print(export_object, "\t")
