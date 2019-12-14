class_name QodotTextureLayeredMesh
extends TextureLayeredMesh
tool

func finalize_image(image: Image, array_size: Vector2) -> Image:
	var texture_size = image.get_size()

	var final_image = Image.new()
	final_image.create(array_size.x, array_size.y, false, image.get_format())

	var image_pos = (array_size - texture_size) / 2.0
	var tile_count = array_size / texture_size

	for x_idx in range(-ceil(tile_count.x), ceil(tile_count.x)):
		for y_idx in range(-ceil(tile_count.y), ceil(tile_count.y)):
			final_image.blit_rect(image, Rect2(Vector2.ZERO, texture_size), image_pos + (texture_size * Vector2(x_idx, y_idx)))

	return final_image
