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
