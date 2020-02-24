class_name QuakeWadImportPlugin
extends EditorImportPlugin
tool

enum WadEntryType {
	Palette = 0x40,
	SBarPic = 0x42,
	MipsTexture = 0x44,
	ConsolePic = 0x45
}

const TEXTURE_NAME_LENGTH := 16
const MAX_MIP_LEVELS := 4

func get_importer_name() -> String:
	return 'qodot.wad'

func get_visible_name() -> String:
	return 'Quake Texture WAD'

func get_resource_type() -> String:
	return 'Resource'

func get_recognized_extensions() -> Array:
	return ['wad']

func get_save_extension() -> String:
	return 'tres'

func get_import_options(preset) -> Array:
	return [
		{
			'name': 'palette_file',
			'default_value': 'res://addons/qodot/palette.lmp',
			'property_hint': PROPERTY_HINT_FILE,
			'hint_string': '*.lmp'
		}
	]

func get_option_visibility(option: String, options: Dictionary) -> bool:
	return true

func get_preset_count() -> int:
	return 0

func import(source_file, save_path, options, r_platform_variants, r_gen_files) -> int:
	var save_path_str : String = '%s.%s' % [save_path, get_save_extension()]

	var file := File.new()
	var err : int = file.open(source_file, File.READ)

	if err != OK:
		print(['Error opening .wad file: ', err])
		return err

	var palette_path : String = options['palette_file']
	var palette_file : QuakePaletteFile = load(palette_path) as QuakePaletteFile
	if not palette_file:
		print('Error: Invalid palette file')
		return ERR_CANT_ACQUIRE_RESOURCE

	# Read WAD header
	var magic : PoolByteArray = file.get_buffer(4)
	var magic_string : String = magic.get_string_from_ascii()

	if(magic_string != 'WAD2'):
		print('Error: Invalid WAD magic')
		return ERR_INVALID_DATA

	var num_entries : int = file.get_32()
	var dir_offset : int = file.get_32()

	# Read entry list
	file.seek(0)
	file.seek(dir_offset)

	var entries : Array = []

	for entry_idx in range(0, num_entries):
		var offset : int = file.get_32()
		var in_wad_size : int = file.get_32()
		var size : int = file.get_32()
		var type : int = file.get_8()
		var compression : int = file.get_8()
		var unknown : int = file.get_16()
		var name : PoolByteArray = file.get_buffer(TEXTURE_NAME_LENGTH)
		var name_string : String = name.get_string_from_ascii()

		if type == WadEntryType.MipsTexture:
			entries.append([
				offset,
				in_wad_size,
				size,
				type,
				compression,
				name_string
			])

	# Read mip textures
	var texture_data_array: Array = []
	for entry in entries:
		var offset : int = entry[0]
		file.seek(0)
		file.seek(offset)

		var name : PoolByteArray = file.get_buffer(TEXTURE_NAME_LENGTH)
		var name_string : String = name.get_string_from_ascii()

		var width : int = file.get_32()
		var height : int = file.get_32()

		var mip_offsets : Array = []
		for idx in range(0, MAX_MIP_LEVELS):
			mip_offsets.append(file.get_32())

		var num_pixels : int = width * height
		texture_data_array.append([name_string, width, height, file.get_buffer(num_pixels)])

	# Create texture resources
	var textures : Dictionary = {}

	for texture_data in texture_data_array:
		var name : String = texture_data[0]
		var width : int = texture_data[1]
		var height : int = texture_data[2]
		var pixels : PoolByteArray = texture_data[3]

		var pixels_rgb := PoolByteArray()
		for palette_color in pixels:
			var rgb_color := palette_file.colors[palette_color] as Color
			pixels_rgb.append(rgb_color.r8)
			pixels_rgb.append(rgb_color.g8)
			pixels_rgb.append(rgb_color.b8)

		var texture_image := Image.new()
		texture_image.create_from_data(width, height, false, Image.FORMAT_RGB8, pixels_rgb)

		var texture := ImageTexture.new()
		texture.create_from_image(texture_image, Texture.FLAG_MIPMAPS | Texture.FLAG_REPEAT | Texture.FLAG_ANISOTROPIC_FILTER)

		textures[name] = texture

	# Save WAD resource
	var wad_resource := QuakeWadFile.new(textures)
	return ResourceSaver.save(save_path_str, wad_resource)
