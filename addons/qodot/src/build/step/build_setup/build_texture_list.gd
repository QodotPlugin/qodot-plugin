class_name QodotBuildTextureList
extends QodotBuildStep

func get_name() -> String:
	return "texture_list"

func get_type() -> int:
	return self.Type.SINGLE

func get_build_params() -> Array:
	return [
		'brush_data_dict'
	]

func _run(context) -> Dictionary:
	var brush_data_dict = context['brush_data_dict']

	var map_reader = QuakeMapReader.new()
	var texture_list = map_reader.get_texture_list(brush_data_dict)

	return {
		'texture_list': texture_list
	}
