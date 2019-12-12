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

	# Build texture array
	var texture_array = TextureArray.new()

	var max_size = Vector2.ZERO
	for size in sizes:
		if size > max_size:
			max_size = size

	print("Creating texture array")
	texture_array.create(
		max_size.x, max_size.y, textures.size(),
		texture_format,
		Texture.FLAG_REPEAT | Texture.FLAG_MIPMAPS | Texture.FLAG_ANISOTROPIC_FILTER
	)

	print("Populating texture array")
	for texture_idx in range(0, textures.size()):
		var texture = textures[texture_idx]
		var src_image = texture.get_data()
		texture_array.set_layer_data(src_image, texture_idx)

	# Create atlas data texture
	var atlas_data_image = Image.new()
	atlas_data_image.create(textures.size(), 1, false, Image.FORMAT_RGF)

	atlas_data_image.lock()
	for texture_name in texture_names:
		var texture_idx = texture_names.find(texture_name)
		var texture_size = sizes[texture_idx]
		atlas_data_image.set_pixel(
			texture_idx,
			0,
			Color(texture_size.x / max_size.x, texture_size.y / max_size.y, 0.0, 0.0)
		)
	atlas_data_image.unlock()

	var atlas_data_texture = ImageTexture.new()
	atlas_data_texture.create_from_image(atlas_data_image, 0)

	# Return data
	print("Returning data")
	return ["data", texture_names, sizes, texture_array, atlas_data_texture]
