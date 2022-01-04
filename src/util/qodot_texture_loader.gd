class_name QodotTextureLoader

const TEXTURE_EMPTY := '__TB_empty'	# TrenchBroom empty texture string

enum PBRSuffix {
	NORMAL,
	METALLIC,
	ROUGHNESS,
	EMISSION,
	AO
}

# Suffix string / Godot enum / StandardMaterial3D property
const PBR_SUFFIX_NAMES := {
	PBRSuffix.NORMAL: 'normal',
	PBRSuffix.METALLIC: 'metallic',
	PBRSuffix.ROUGHNESS: 'roughness',
	PBRSuffix.EMISSION: 'emission',
	PBRSuffix.AO: 'ao',
}

const PBR_SUFFIX_PATTERNS := {
	PBRSuffix.NORMAL: '%s_normal.%s',
	PBRSuffix.METALLIC: '%s_metallic.%s',
	PBRSuffix.ROUGHNESS: '%s_roughness.%s',
	PBRSuffix.EMISSION: '%s_emission.%s',
	PBRSuffix.AO: '%s_ao.%s',
}

var PBR_SUFFIX_TEXTURES := {
	PBRSuffix.NORMAL: StandardMaterial3D.TEXTURE_NORMAL,
	PBRSuffix.METALLIC: StandardMaterial3D.TEXTURE_METALLIC,
	PBRSuffix.ROUGHNESS: StandardMaterial3D.TEXTURE_ROUGHNESS,
	PBRSuffix.EMISSION: StandardMaterial3D.TEXTURE_EMISSION,
	PBRSuffix.AO: StandardMaterial3D.TEXTURE_AMBIENT_OCCLUSION,
}

const PBR_SUFFIX_PROPERTIES := {
	PBRSuffix.NORMAL: 'normal_enabled',
	PBRSuffix.EMISSION: 'emission_enabled',
	PBRSuffix.AO: 'ao_enabled',
}

# Parameters
var base_texture_path: String
var texture_extensions: PackedStringArray
var texture_wads: Array

# Instances
var directory := Directory.new()
var texture_wad_resources : Array = []
var unshaded := false

# Getters
func get_pbr_suffix_pattern(suffix: int) -> String:
	if not suffix in PBR_SUFFIX_NAMES:
		return ''

	var pattern_setting := "qodot/textures/%s_pattern" % [PBR_SUFFIX_NAMES[suffix]]
	if ProjectSettings.has_setting(pattern_setting):
		return ProjectSettings.get_setting(pattern_setting)

	return PBR_SUFFIX_PATTERNS[suffix]

# Overrides
func _init(
		base_texture_path: String,
		texture_extensions: PackedStringArray,
		texture_wads: Array
	) -> void:
	self.base_texture_path = base_texture_path
	self.texture_extensions = texture_extensions

	load_texture_wad_resources(texture_wads)

# Business Logic
func load_texture_wad_resources(texture_wads: Array) -> void:
	texture_wad_resources.clear()

	for texture_wad in texture_wads:
		if texture_wad and not texture_wad in texture_wad_resources:
			texture_wad_resources.append(texture_wad)

func load_textures(texture_list: Array) -> Dictionary:
	var texture_dict := {}

	for texture_name in texture_list:
		texture_dict[texture_name] = load_texture(texture_name)

	return texture_dict

func load_texture(texture_name: String) -> Texture2D:
	if(texture_name == TEXTURE_EMPTY):
		return null

	# Load albedo texture if it exists
	for texture_extension in texture_extensions:
		var texture_path := "%s/%s.%s" % [base_texture_path, texture_name, texture_extension]
		if ResourceLoader.exists(texture_path, "Texture2D"):
			return load(texture_path) as Texture2D

	var texture_name_lower : String = texture_name.to_lower()
	for texture_wad in texture_wad_resources:
		if texture_name_lower in texture_wad.textures:
			return texture_wad.textures[texture_name_lower]

	return null

func create_materials(texture_list: Array, material_extension: String, default_material: Material) -> Dictionary:
	var texture_materials := {}
	prints("TEXLI", texture_list)
	for texture in texture_list:
		texture_materials[texture] = create_material(
			texture,
			material_extension,
			default_material
		)
	return texture_materials

func create_material(
	texture_name: String,
	material_extension: String,
	default_material: StandardMaterial3D
	) -> StandardMaterial3D:
	# Autoload material if it exists
	var material_dict := {}

	var material_path = "%s/%s.%s" % [base_texture_path, texture_name, material_extension]
	if not material_path in material_dict and directory.file_exists(material_path):
		var loaded_material: Material = load(material_path)
		if loaded_material:
			material_dict[material_path] = loaded_material

	# If material already exists, use it
	if material_path in material_dict:
		return material_dict[material_path]

	var material : StandardMaterial3D = null

	if default_material:
		material = default_material.duplicate()
	else:
		material = StandardMaterial3D.new()
	var texture : Texture2D = load_texture(texture_name)
	if not texture:
		return material

	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED if unshaded else BaseMaterial3D.SHADING_MODE_PER_PIXEL

	material.set_texture(StandardMaterial3D.TEXTURE_ALBEDO, texture)

	var pbr_textures : Dictionary = get_pbr_textures(texture_name)
	
	for pbr_suffix in PBRSuffix.values():
		var suffix = pbr_suffix
		var tex = pbr_textures[suffix]
		if tex:
			var enable_prop : String = PBR_SUFFIX_PROPERTIES[suffix] if suffix in PBR_SUFFIX_PROPERTIES else ""
			if(enable_prop != ""):
				material.set(enable_prop, true)

			material.set_texture(PBR_SUFFIX_TEXTURES[suffix], tex)

		material_dict[material_path] = material

	return material

# PBR texture fetching
func get_pbr_textures(texture_name: String) -> Dictionary:
	var pbr_textures := {}
	for pbr_suffix in PBRSuffix.values():
		prints("CHECK SUFFIX", pbr_suffix)
		pbr_textures[pbr_suffix] = get_pbr_texture(texture_name, pbr_suffix)

	return pbr_textures

func get_pbr_texture(texture: String, suffix: PBRSuffix) -> Texture2D:
	var texture_comps : PackedStringArray = texture.split('/')

	if texture_comps.size() == 0:
		return null

	for texture_extension in texture_extensions:
		var path := "%s/%s/%s" % [
			base_texture_path,
			'/'.join(texture_comps),
			get_pbr_suffix_pattern(suffix) % [
				texture_comps[-1],
				texture_extension
			]
		]

		if(directory.file_exists(path)):
			return load(path) as Texture2D

	return null
