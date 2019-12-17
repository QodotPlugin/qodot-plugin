class_name QodotBuildTextureLayeredMeshAtlas
extends QodotBuildStep

func get_name() -> String:
	return "texture_layered_mesh_atlas"

func get_type() -> int:
	return self.Type.SINGLE

func get_build_params() -> Array:
	return ['texture_layered_mesh', 'texture_atlas']

func _run(context) -> Dictionary:
	var texture_layered_mesh = context['texture_layered_mesh']
	var texture_atlas = context['texture_atlas']

	var atlas_textures = texture_atlas['atlas_textures']
	var atlas_data_texture = texture_atlas['atlas_data_texture']

	# Configure atlas material
	texture_layered_mesh.set_array_data(atlas_textures)
	texture_layered_mesh.shader_material.set_shader_param('atlas_data', atlas_data_texture)

	return {}
