class_name QodotBuildTextureAtlas
extends QodotBuildStep

var texture_format = Image.FORMAT_RGB8

func get_name() -> String:
	return "texture_atlas"

func get_type() -> int:
	return self.Type.SINGLE

func get_build_params() -> Array:
	return [
		'material_dict'
	]

func _run(context) -> Array:
	var material_dict = context['material_dict'][0][1]

	# Get texture data
	var texture_names = []
	var textures = []
	var sizes = []
	for material_key in material_dict:
		var material = material_dict[material_key]
		if material:
			var texture = material.get_texture(SpatialMaterial.TEXTURE_ALBEDO)
			var size = texture.get_size()
			texture_names.append(material_key)
			textures.append(texture)
			sizes.append(size)

	var max_size = Vector2.ZERO
	for size in sizes:
		if size.x > max_size.x:
			max_size.x = size.x
		if size.y > max_size.y:
			max_size.y = size.y

	var atlas_center = max_size / 2.0

	var positions = []
	for size in sizes:
		var half_size = size / 2.0
		var position = atlas_center - half_size
		positions.append(position)

	# Create atlas data texture
	var atlas_data_image = Image.new()
	atlas_data_image.create(textures.size(), 1, false, Image.FORMAT_RGBAF)

	atlas_data_image.lock()
	for texture_name in texture_names:
		var texture_idx = texture_names.find(texture_name)
		var texture_position = positions[texture_idx]
		var texture_size = sizes[texture_idx]
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
	print("Returning data")
	return ["data", texture_names, positions, sizes, textures, atlas_data_texture]
