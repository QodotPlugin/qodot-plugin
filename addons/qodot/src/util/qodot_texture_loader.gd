class_name QodotTextureLoader

const TEXTURE_EMPTY := '__TB_empty'	# TrenchBroom empty texture string

const PBR_NORMAL := 'normal'
const PBR_METALLIC := 'metallic'
const PBR_ROUGHNESS := 'roughness'
const PBR_EMISSION := 'emissive'
const PBR_AO := 'ao'
const PBR_DEPTH := 'depth'

# Suffix string / Godot enum / SpatialMaterial property
const PBR_SUFFICES : Array = [
	[ PBR_NORMAL, SpatialMaterial.TEXTURE_NORMAL, 'normal_enabled' ],
	[ PBR_METALLIC, SpatialMaterial.TEXTURE_METALLIC ],
	[ PBR_ROUGHNESS, SpatialMaterial.TEXTURE_ROUGHNESS ],
	[ PBR_EMISSION, SpatialMaterial.TEXTURE_EMISSION, 'emission_enabled' ],
	[ PBR_AO, SpatialMaterial.TEXTURE_AMBIENT_OCCLUSION, 'ao_enabled' ],
	[ PBR_DEPTH, SpatialMaterial.TEXTURE_DEPTH, 'depth_enabled' ]
]

# Parameters
var base_texture_path: String
var texture_extension: String
var texture_wads: Array

# Instances
var directory := Directory.new()

var texture_wad_resources : Array = []

func _init(
		base_texture_path: String,
		texture_extension: String,
		texture_wads: Array
	) -> void:
	self.base_texture_path = base_texture_path
	self.texture_extension = texture_extension

	load_texture_wad_resources(texture_wads)

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
	var texture_path : String = base_texture_path + '/' + texture_name + texture_extension

	if(directory.file_exists(texture_path)):
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
	if(texture_name == TEXTURE_EMPTY):
		return null

	# Autoload material if it exists
	var material_dict := {}

	var material_path = base_texture_path + '/' + texture_name + material_extension
	if not material_path in material_dict and directory.file_exists(material_path):
		var loaded_material: Material = load(material_path)
		if loaded_material:
			material_dict[material_path] = loaded_material

	# If material already exists, use it
	if material_path in material_dict:
		return material_dict[material_path]

	var texture : Texture = load_texture(texture_name)
	if not texture:
		return null

	var material : SpatialMaterial = null

	if default_material:
		material = default_material.duplicate()
	else:
		material = SpatialMaterial.new()

	material.set_texture(SpatialMaterial.TEXTURE_ALBEDO, texture)

	var pbr_textures : Dictionary = get_pbr_textures(texture_name, texture)
	for pbr_suffix in PBR_SUFFICES:
		if(pbr_suffix != null):
			var tex = pbr_textures[pbr_suffix[0]]
			if(tex != null):
				var enable_prop : String = pbr_suffix[2] if pbr_suffix.size() >= 3 else ""
				if(enable_prop != ""):
					material.set(enable_prop, true)

				var texture_enum : int = pbr_suffix[1]
				material.set_texture(texture_enum, tex)

		material_dict[material_path] = material

	return material

# PBR texture fetching
func get_pbr_textures(texture_name: String, texture: Texture) -> Dictionary:
	var pbr_textures := {}
	for suffix in PBR_SUFFICES:
		var suffix_string : String = suffix[0]
		pbr_textures[suffix_string] = get_pbr_texture(texture_name, suffix_string)

	return pbr_textures

func create_pbr_material(texture_name: String, albedo_texture: Texture, default_material: SpatialMaterial) -> SpatialMaterial:
	var material : SpatialMaterial = null

	if default_material:
		material = default_material.duplicate()
	else:
		material = SpatialMaterial.new()

	material.set_texture(SpatialMaterial.TEXTURE_ALBEDO, albedo_texture)

	var pbr_textures : Dictionary = get_pbr_textures(texture_name, albedo_texture)
	for pbr_suffix in PBR_SUFFICES:
		if(pbr_suffix != null):
			var tex : Texture = pbr_textures[pbr_suffix[0]]
			if(tex != null):
				var enable_prop : String = pbr_suffix[2] if pbr_suffix.size() >= 3 else ""
				if(enable_prop != ""):
					material.set(enable_prop, true)

				var texture_enum : int = pbr_suffix[1]
				material.set_texture(texture_enum, tex)

	return material

func get_pbr_texture(texture_name: String, suffix: String) -> Texture:
	var texture_comps : PoolStringArray = texture_name.split('/')

	if texture_comps.size() == 0:
		return null

	var texture_string = ''
	for comp in texture_comps:
		texture_string += '/' + comp

	var path : String = base_texture_path + texture_string + '/' + texture_comps[-1] + '_' + suffix + texture_extension
	if(directory.file_exists(path)):
		return load(path) as Texture

	return null
