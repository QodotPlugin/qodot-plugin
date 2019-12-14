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

func get_map_attach_path():
	return NodePath('./')

func get_entity_attach_path(entity_idx: int) -> NodePath:
	return NodePath('./Entity' + String(entity_idx))


func get_brush_attach_path(entity_idx: int, brush_idx: int) -> NodePath:
	return NodePath('./Entity' + String(entity_idx) + '/Brush' + String(brush_idx))
