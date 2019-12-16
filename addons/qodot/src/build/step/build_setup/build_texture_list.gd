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

	var texture_list = get_texture_list(brush_data_dict)

	print("\nMap textures:")
	QodotPrinter.print_typed(texture_list)

	return {
		'texture_list': texture_list
	}

func get_texture_list(brush_data_dict: Dictionary) -> Array:
	var texture_list = []

	for entity_idx in brush_data_dict:
		var entity_brushes = brush_data_dict[entity_idx]
		for brush_idx in entity_brushes:
			var brush_faces = entity_brushes[brush_idx]
			for face_data in brush_faces:
				var face_texture = face_data[1]
				if not face_texture in texture_list:
					texture_list.append(face_texture)

	texture_list.sort()

	return texture_list