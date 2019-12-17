class_name QodotBuildUnwrapUVs
extends QodotBuildStep

var resolution_scale = 0.066

func get_name() -> String:
	return "unwrap_uvs"

func get_type() -> int:
	return self.Type.SINGLE

func get_finalize_params() -> Array:
	return ['meshes_to_unwrap', 'inverse_scale_factor']

func get_wants_finalize() -> bool:
	return true

func _run(context: Dictionary) -> Dictionary:
	return {
		'meshes_to_unwrap': {}
	}

func _finalize(context: Dictionary) -> Dictionary:
	var meshes_to_unwrap = context['meshes_to_unwrap']
	var inverse_scale_factor = context['inverse_scale_factor']

	for mesh_key in meshes_to_unwrap:
		var mesh = meshes_to_unwrap[mesh_key]
		mesh.lightmap_unwrap(Transform.IDENTITY, (1.0 / resolution_scale) / inverse_scale_factor)

	return {}
