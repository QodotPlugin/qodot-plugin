class_name QodotTextureLoader

const TEXTURE_EMPTY := '__TB_empty'	# TrenchBroom empty texture string

enum PBRSuffix {
	NORMAL,
	METALLIC,
	ROUGHNESS,
	EMISSION,
	AO,
	DEPTH
}

# Suffix string / Godot enum / SpatialMaterial property
const PBR_SUFFIX_NAMES := {
	PBRSuffix.NORMAL: 'normal',
	PBRSuffix.METALLIC: 'metallic',
	PBRSuffix.ROUGHNESS: 'roughness',
	PBRSuffix.EMISSION: 'emission',
	PBRSuffix.AO: 'ao',
	PBRSuffix.DEPTH: 'depth',
}

const PBR_SUFFIX_PATTERNS := {
	PBRSuffix.NORMAL: '%s_normal.%s',
	PBRSuffix.METALLIC: '%s_metallic.%s',
	PBRSuffix.ROUGHNESS: '%s_roughness.%s',
	PBRSuffix.EMISSION: '%s_emission.%s',
	PBRSuffix.AO: '%s_ao.%s',
	PBRSuffix.DEPTH: '%s_depth.%s',
}

const PBR_SUFFIX_TEXTURES := {
	PBRSuffix.NORMAL: SpatialMaterial.TEXTURE_NORMAL,
	PBRSuffix.METALLIC: SpatialMaterial.TEXTURE_METALLIC,
	PBRSuffix.ROUGHNESS: SpatialMaterial.TEXTURE_ROUGHNESS,
	PBRSuffix.EMISSION: SpatialMaterial.TEXTURE_EMISSION,
	PBRSuffix.AO: SpatialMaterial.TEXTURE_AMBIENT_OCCLUSION,
	PBRSuffix.DEPTH: SpatialMaterial.TEXTURE_DEPTH,
}

const PBR_SUFFIX_PROPERTIES := {
	PBRSuffix.NORMAL: 'normal_enabled',
	PBRSuffix.EMISSION: 'emission_enabled',
	PBRSuffix.AO: 'ao_enabled',
	PBRSuffix.DEPTH: 'depth_enabled',
}

# Parameters
var base_texture_path: String
var texture_extensions: PoolStringArray
var texture_wads: Array

# Instances
var directory := Directory.new()
var texture_wad_resources : Array = []

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
		texture_extensions: PoolStringArray,
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

func load_texture(texture_name: String) -> Texture:
	if(texture_name == TEXTURE_EMPTY):
		return null

	# Load albedo texture if it exists
	for texture_extension in texture_extensions:
		var texture_path := "%s/%s.%s" % [base_texture_path, texture_name, texture_extension]
		if ResourceLoader.exists(texture_path, "Texture"):
			return load(texture_path) as Texture

	var texture_name_lower : String = texture_name.to_lower()
	for texture_wad in texture_wad_resources:
		if texture_name_lower in texture_wad.textures:
			return texture_wad.textures[texture_name_lower]

	return null

func create_materials(texture_list: Array, material_extension: String, default_material: Material) -> Dictionary:
	var texture_materials := {}
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
	default_material: SpatialMaterial
	) -> SpatialMaterial:
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

	var material : SpatialMaterial = null

	if default_material:
		material = default_material.duplicate()
	else:
		material = SpatialMaterial.new()

	var texture : Texture = load_texture(texture_name)
	if not texture:
		return material

	material.set_texture(SpatialMaterial.TEXTURE_ALBEDO, texture)

	var pbr_textures : Dictionary = get_pbr_textures(texture_name)
	for pbr_suffix in PBRSuffix:
		var suffix = PBRSuffix[pbr_suffix]
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
	for pbr_suffix in PBRSuffix:
		var suffix = PBRSuffix[pbr_suffix]
		pbr_textures[suffix] = get_pbr_texture(texture_name, suffix)

	return pbr_textures

func get_pbr_texture(texture: String, suffix: int) -> Texture:
	var texture_comps : PoolStringArray = texture.split('/')

	if texture_comps.size() == 0:
		return null

	for texture_extension in texture_extensions:
		var path := "%s/%s/%s" % [
			base_texture_path,
			texture_comps.join('/'),
			get_pbr_suffix_pattern(suffix) % [
				texture_comps[-1],
				texture_extension
			]
		]

		if(directory.file_exists(path)):
			return load(path) as Texture

	return null
