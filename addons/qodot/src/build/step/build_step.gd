class_name QodotBuildStep

enum Type {
	SINGLE,
	PER_ENTITY,
	PER_BRUSH
}

func get_name() -> String:
	return "build_step"

func get_type() -> int:
	return Type.SINGLE

func get_build_params() -> Array:
	return []

func get_finalize_params() -> Array:
	return []

func get_wants_finalize() -> bool:
	return false

func _run(context) -> Dictionary:
	return {}

func _finalize(context) -> Dictionary:
	return {}

func get_entity_key(entity_idx):
	return 'entity_' + String(entity_idx)

func get_brush_key(brush_idx):
	return 'brush_' + String(brush_idx)

func get_face_key(face_idx):
	return 'face_' + String(face_idx)

func get_entity_brush_key(entity_idx, brush_idx):
	return get_entity_key(entity_idx) + '_' + get_brush_key(brush_idx)

func get_entity_brush_face_key(entity_idx, brush_idx, face_idx):
	return get_entity_brush_key(entity_idx, brush_idx) + '_' + get_face_key(face_idx)

func create_brush_from_face_data(face_data: Array) -> QuakeBrush:
	var brush_faces = []

	for face in face_data:
		brush_faces.append(QuakeFace.new(face))

	return QuakeBrush.new(brush_faces)

func foreach_entity(brush_data_dict: Dictionary, entity_properties_array: Array, predicate: FuncRef, function: FuncRef):
	var entity_results = {}

	for entity_key in brush_data_dict:
		var entity_properties = entity_properties_array[entity_key]
		var entity_brushes = brush_data_dict[entity_key]

		if not predicate.call_func(entity_properties):
			continue

		entity_results[entity_key] = function.call_func(entity_key, entity_properties, entity_brushes)

	return entity_results

func foreach_brush(entity_key, entity_properties: Dictionary, entity_brushes: Dictionary, predicate: FuncRef, function: FuncRef):
	var brush_results = {}

	for brush_key in entity_brushes:
		var face_data = entity_brushes[brush_key]
		var brush = create_brush_from_face_data(face_data)

		if not predicate.call_func(entity_properties, brush):
			continue

		brush_results[brush_key] = function.call_func(entity_key, brush_key, entity_properties, brush)

	return brush_results

func foreach_face(entity_key, entity_properties: Dictionary, brush_key, brush: QuakeBrush, predicate: FuncRef, function: FuncRef):
	var face_results = {}

	for face_idx in range(0, brush.faces.size()):
		var face = brush.faces[face_idx]

		if not predicate.call_func(entity_properties, brush, face):
			continue

		face_results[face_idx] = function.call_func(entity_key, entity_properties, brush_key, brush, face_idx, face)

	return face_results

func foreach_entity_brush(entity_properties_array: Array, brush_data_dict: Dictionary, entity_predicate: FuncRef, brush_predicate: FuncRef, function: FuncRef):
	var entity_brush_results = {}

	for entity_key in brush_data_dict:
		var entity_properties = entity_properties_array[entity_key]
		var entity_brushes = brush_data_dict[entity_key]

		if not entity_predicate.call_func(entity_properties):
			continue

		entity_brush_results[entity_key] = foreach_brush(entity_key, entity_properties, entity_brushes, brush_predicate, function)

	return entity_brush_results

func foreach_entity_brush_face(entity_properties_array: Array, brush_data_dict: Dictionary, entity_predicate: FuncRef, brush_predicate: FuncRef, face_predicate: FuncRef, function: FuncRef):
	var entity_brush_face_results = {}

	for entity_key in brush_data_dict:
		var entity_properties = entity_properties_array[entity_key]
		var entity_brushes = brush_data_dict[entity_key]

		if not entity_predicate.call_func(entity_properties):
			continue

		for brush_key in entity_brushes:
			var face_data = entity_brushes[brush_key]
			var brush = create_brush_from_face_data(face_data)

			if not brush_predicate.call_func(entity_properties, brush):
				continue

			entity_brush_face_results[brush_key] = foreach_face(entity_key, entity_properties, brush_key, brush, face_predicate, function)

	return entity_brush_face_results

func foreach_brush_face(entity_key, entity_properties: Dictionary, entity_brushes: Dictionary, brush_predicate: FuncRef, face_predicate: FuncRef, function: FuncRef):
	var brush_face_results = {}

	for brush_key in entity_brushes:
		var face_data = entity_brushes[brush_key]
		var brush = create_brush_from_face_data(face_data)

		if not brush_predicate.call_func(entity_properties, brush):
			continue

		brush_face_results[brush_key] = foreach_face(entity_key, entity_properties, brush_key, brush, face_predicate, function)

	return brush_face_results


func boolean_true(a = null, b = null, c = null) -> bool:
	return true
