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

func _run(context) -> Array:
	return [null]

func _finalize(context) -> void:
	pass
