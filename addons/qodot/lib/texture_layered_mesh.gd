class_name TextureLayeredMesh
extends QodotSpatial
tool

# Constants
const DEBUG = false

# Enums
enum LayeredType {
	TEXTURE_ARRAY,
	TEXTURE_3D
}

enum TextureFormat {
	L8 = Image.FORMAT_L8,
	LA8 = Image.FORMAT_LA8,
	R8 = Image.FORMAT_R8,
	RG8 = Image.FORMAT_RG8,
	RGB8 = Image.FORMAT_RGB8,
	RGBA8 = Image.FORMAT_RGBA8,
	RGBA4444 = Image.FORMAT_RGBA4444,
	RGBA5551 = Image.FORMAT_RGBA5551,
	RF = Image.FORMAT_RF,
	RGF = Image.FORMAT_RGF,
	RGBF = Image.FORMAT_RGBF,
	RGBAF = Image.FORMAT_RGBAF,
	RH = Image.FORMAT_RH,
	RGH = Image.FORMAT_RGH,
	RGBH = Image.FORMAT_RGBH,
	RGBAH = Image.FORMAT_RGBAH,
	RGBE9995 = Image.FORMAT_RGBE9995
}

enum  TextureCompression {
	NONE = -1,
	S3TC = Image.COMPRESS_S3TC,
	PVRTC2 = Image.COMPRESS_PVRTC2,
	PVRTC4 = Image.COMPRESS_PVRTC4,
	ETC = Image.COMPRESS_ETC,
	ETC2 = Image.COMPRESS_ETC2
}


enum  TextureCompressionSource {
	GENERIC = Image.COMPRESS_SOURCE_GENERIC
	SRGB = Image.COMPRESS_SOURCE_SRGB,
	NORMAL = Image.COMPRESS_SOURCE_NORMAL
}

# Exported Variables
export(bool) var reload setget set_reload

export(Array, Mesh) var meshes setget set_meshes
export(ShaderMaterial) var shader_material setget set_shader_material
export(Array, Resource) var array_data setget set_array_data

export(LayeredType) var layered_texture_type = LayeredType.TEXTURE_ARRAY setget set_layered_texture_type
export(String) var shader_parameter = "texture_array" setget set_shader_parameter

export(TextureFormat) var texture_format = TextureFormat.RGBA8 setget set_texture_format
export(TextureCompression) var texture_compression = TextureCompression.NONE setget set_texture_compression
export(TextureCompressionSource) var texture_compression_source = TextureCompressionSource.GENERIC setget set_texture_compression_source
export(float) var texture_lossy_quality = 0.7 setget set_texture_lossy_quality
export(int, FLAGS, "Mipmap", "Repeat", "Filter", "Anisotropic Filter", "Convert to Linear", "Mirrored Repeat", "Video Surface") var texture_flags = Texture.FLAG_MIPMAPS | Texture.FLAG_ANISOTROPIC_FILTER setget set_texture_flags

func _ready():
	regenerate()

# Setters
func set_reload(new_reload):
	regenerate()

func set_meshes(new_meshes):
	if meshes != new_meshes:
		meshes = new_meshes

func set_shader_material(new_shader_material):
	if shader_material != new_shader_material:
		shader_material = new_shader_material

func set_array_data(new_array_data):
	if(array_data != new_array_data):
		array_data = new_array_data

func set_layered_texture_type(new_layered_texture_type):
	if(layered_texture_type != new_layered_texture_type):
		layered_texture_type = new_layered_texture_type

func set_shader_parameter(new_shader_parameter):
	if(shader_parameter != new_shader_parameter):
		shader_parameter = new_shader_parameter

func set_texture_format(new_texture_format):
	if(texture_format != new_texture_format):
		texture_format = new_texture_format

func set_texture_compression(new_texture_compression):
	if(texture_compression != new_texture_compression):
		texture_compression = new_texture_compression

func set_texture_compression_source(new_texture_compression_source):
	if(texture_compression_source != new_texture_compression_source):
		texture_compression_source = new_texture_compression_source

func set_texture_lossy_quality(new_texture_lossy_quality):
	if(texture_lossy_quality != new_texture_lossy_quality):
		texture_lossy_quality = new_texture_lossy_quality

func set_texture_flags(new_texture_flags):
	if(texture_flags != new_texture_flags):
		texture_flags = new_texture_flags

# Business Logic
func regenerate():
	# Remove any existing children
	for child in get_children():
		remove_child(child)
		child.queue_free()

	if meshes.size() <= 0:
		print_log("Error: No mesh")
		return

	if not shader_material:
		print_log("Error: No base shader")
		return

	# Create shader material instance
	print_log("Regenerating material")
	var new_shader_material = shader_material.duplicate()
	print_log("Created shader material: ", new_shader_material)

	if array_data.size() <= 0:
		print_log("Error: No candidate images")
		return

	# Create texture array
	print_log("Regenerating array")
	var texture_array = TextureArray.new()

	var images = []
	var max_size = Vector2.ZERO
	for array_image in array_data:
		if array_image:
			var image = null

			if array_image is Image:
				image = array_image
			elif array_image is Texture:
				image = array_image.get_data()
			elif array_image is SpatialMaterial:
				var texture = array_image.get_texture(SpatialMaterial.TEXTURE_ALBEDO)
				if texture:
					image = texture.get_data()

			if image:
				var image_size = image.get_size()
				if image_size.x > max_size.x:
					max_size.x = image_size.x
				if image_size.y > max_size.y:
					max_size.y = image_size.y
			images.append(image)

	if max_size != Vector2.ZERO:
		texture_array.create(max_size.x, max_size.y, images.size(), texture_format, texture_flags)
		var image_idx = 0
		for image in images:
			if image:
				var image_copy = image.duplicate()

				if(image_copy.is_compressed()):
					print_log("Warning: Copy is compressed, decompressing...")
					image_copy.decompress()

				var image_format = image_copy.get_format()
				if image_format != texture_format:
					image_copy.convert(texture_format)

				var final_image = finalize_image(image_copy, max_size)
				final_image.generate_mipmaps()

				if texture_compression != TextureCompression.NONE:
					final_image.compress(texture_compression, texture_compression_source, texture_lossy_quality)

				texture_array.set_layer_data(final_image, image_idx)
				image_idx += 1

		new_shader_material.set_shader_param(shader_parameter, texture_array)

		print_log("Created texture array with data: ", texture_array.data)

	for mesh in meshes:
		var new_mesh = mesh.duplicate()
		var mesh_instance = MeshInstance.new()
		mesh_instance.set_mesh(new_mesh)
		mesh_instance.set_material_override(new_shader_material)
		add_child(mesh_instance)

func finalize_image(image: Image, array_size: Vector2) -> Image:
	return image

# Utility
func print_log(
	msg1 = '',
	msg2 = '',
	msg3 = '',
	msg4 = '',
	msg5 = '',
	msg6 = '',
	msg7 = '',
	msg8 = ''
	):
	if(DEBUG):
		print(msg1, msg2, msg3, msg4, msg5, msg6, msg7, msg8)