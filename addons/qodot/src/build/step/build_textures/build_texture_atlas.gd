class_name QodotBuildTextureAtlas
extends QodotBuildStep

var texture_format = Image.FORMAT_RGB8

func get_name() -> String:
	return "texture_atlas"

func get_type() -> int:
	return self.Type.SINGLE

func get_build_params() -> Array:
	return ['texture_dict']

func _run(context) -> Dictionary:
	var texture_dict = context['texture_dict']

	# Get texture data
	var texture_names = []
	var atlas_textures = []
	var atlas_sizes = []

	for texture_key in texture_dict:
		var texture = texture_dict[texture_key]
		if texture:
			texture_names.append(texture_key)
			atlas_textures.append(texture)
			atlas_sizes.append(texture.get_size())

	if texture_names.size() <= 0:
		print("No textures to atlas.")
		return {}

	var max_size = Vector2.ZERO
	for size in atlas_sizes:
		if size.x > max_size.x:
			max_size.x = size.x
		if size.y > max_size.y:
			max_size.y = size.y

	var atlas_center = max_size / 2.0

	var atlas_positions = []
	for size in atlas_sizes:
		var half_size = size / 2.0
		var position = atlas_center - half_size
		atlas_positions.append(position)

	# Create atlas data texture
	var atlas_data_image = Image.new()
	atlas_data_image.create(atlas_textures.size(), 1, false, Image.FORMAT_RGBAF)

	atlas_data_image.lock()
	for texture_name in texture_names:
		var texture_idx = texture_names.find(texture_name)
		var texture_position = atlas_positions[texture_idx]
		var texture_size = atlas_sizes[texture_idx]
		var half_size = texture_size / 2.0
		atlas_data_image.set_pixel(
			texture_idx,
			0,
			Color(
				texture_position.x / max_size.x,
				texture_position.y / max_size.y,
				texture_size.x / max_size.x,
				texture_size.y / max_size.y
			)
		)
	atlas_data_image.unlock()

	var atlas_data_texture = ImageTexture.new()
	atlas_data_texture.create_from_image(atlas_data_image, 0)

	# Return data
	return {
		'texture_atlas': {
			'atlas_texture_names': texture_names,
			'atlas_positions': atlas_positions,
			'atlas_sizes': atlas_sizes,
			'atlas_textures': atlas_textures,
			'atlas_data_texture': atlas_data_texture
		}
	}
