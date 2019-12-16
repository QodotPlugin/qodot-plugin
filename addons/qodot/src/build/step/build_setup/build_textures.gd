class_name QodotBuildTextures
extends QodotBuildStep

func get_name() -> String:
	return "textures"

func get_type() -> int:
	return self.Type.SINGLE

func get_build_params() -> Array:
	return [
		'texture_list',
		'base_texture_path',
		'material_extension',
		'texture_extension',
		'texture_wads',
		'default_material',
	]

func _run(context) -> Dictionary:
	var texture_list = context['texture_list']
	var base_texture_path = context['base_texture_path']
	var material_extension = context['material_extension']
	var texture_extension = context['texture_extension']
	var texture_wads = context['texture_wads']
	var default_material = context['default_material']

	var texture_loader = QodotTextureLoader.new(
		base_texture_path,
		texture_extension,
		texture_wads
	)

	var texture_dict = texture_loader.load_textures(texture_list)

	return {
		'texture_dict': texture_dict
	}
