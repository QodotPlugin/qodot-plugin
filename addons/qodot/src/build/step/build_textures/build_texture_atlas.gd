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

	var atlas_dict = Geometry.make_atlas(sizes)
	var atlas_points = atlas_dict['points']
	var atlas_size = atlas_dict['size']

	var atlas_image = Image.new()
	atlas_image.create(atlas_size.x, atlas_size.y, false, texture_format)

	for texture_idx in range(0, textures.size()):
		var texture = textures[texture_idx]
		var src_image = texture.get_data()
		atlas_image.blit_rect(src_image, Rect2(Vector2.ZERO, src_image.get_size()), atlas_points[texture_idx])

	var result_image = ImageTexture.new()
	result_image.create_from_image(atlas_image, 0)

	return ["data", result_image, texture_names, atlas_points, sizes]
