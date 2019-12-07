class_name QodotTextureLoader

const TEXTURE_EMPTY = '__TB_empty'	# TrenchBroom empty texture string

const PBR_NORMAL = 'normal'
const PBR_METALLIC = 'metallic'
const PBR_ROUGHNESS = 'roughness'
const PBR_EMISSION = 'emissive'
const PBR_AO = 'ao'
const PBR_DEPTH = 'depth'

# Suffix string / Godot enum / SpatialMaterial property
const PBR_SUFFICES = [
	[ PBR_NORMAL, SpatialMaterial.TEXTURE_NORMAL, 'normal_enabled' ],
	[ PBR_METALLIC, SpatialMaterial.TEXTURE_METALLIC ],
	[ PBR_ROUGHNESS, SpatialMaterial.TEXTURE_ROUGHNESS ],
	[ PBR_EMISSION, SpatialMaterial.TEXTURE_EMISSION, 'emission_enabled' ],
	[ PBR_AO, SpatialMaterial.TEXTURE_AMBIENT_OCCLUSION, 'ao_enabled' ],
	[ PBR_DEPTH, SpatialMaterial.TEXTURE_DEPTH, 'depth_enabled' ]
]

var material_dict = {}
var texture_directory = Directory.new()

func load_texture_materials(
	texture_list: Array,
	base_texture_path: String,
	material_extension: String,
	texture_extension: String,
	default_material = null
	) -> Dictionary:
	var texture_materials = {}
	for texture in texture_list:
		texture_materials[texture] = get_spatial_material(texture, base_texture_path, material_extension, texture_extension, default_material)
	return texture_materials

func get_spatial_material(
	texture_name: String,
	base_texture_path: String,
	material_extension: String,
	texture_extension: String,
	default_material = null
	):
	var spatial_material = null

	if(texture_name != TEXTURE_EMPTY):
		texture_directory.change_dir(base_texture_path)

		# Autoload material if it exists
		var material_path = base_texture_path + '/' + texture_name + material_extension

		if not material_path in material_dict and texture_directory.file_exists(material_path):
			var loaded_material: SpatialMaterial = load(material_path)
			material_dict[material_path] = loaded_material

		if material_path in material_dict:
			# If material already exists, use it
			spatial_material = material_dict[material_path]
		else:
			# Load albedo texture if it exists
			var texture_path = base_texture_path + '/' + texture_name + texture_extension

			var texture = null
			if(texture_directory.file_exists(texture_path)):
				texture = load(texture_path)

			if texture:
				if default_material:
					spatial_material = default_material.duplicate()
				else:
					spatial_material = SpatialMaterial.new()

				spatial_material.set_texture(SpatialMaterial.TEXTURE_ALBEDO, texture)

				var pbr_textures = get_pbr_textures(base_texture_path, texture_name, texture_extension)
				for pbr_suffix in PBR_SUFFICES:
					if(pbr_suffix != null):
						var tex = pbr_textures[pbr_suffix[0]]
						if(tex != null):
							var enable_prop = pbr_suffix[2] if pbr_suffix.size() >= 3 else null
							if(enable_prop):
								spatial_material.set(enable_prop, true)

							var texture_enum = pbr_suffix[1]
							spatial_material.set_texture(texture_enum, tex)

				material_dict[material_path] = spatial_material

	return spatial_material

# PBR texture fetching
func get_pbr_textures(base_texture_path, texture, texture_extension):
	var pbr_textures = {}
	for suffix in PBR_SUFFICES:
		var suffix_string = suffix[0]
		pbr_textures[suffix_string] = get_pbr_texture(base_texture_path, texture, suffix_string, texture_extension)
	return pbr_textures

func get_pbr_texture(base_texture_path, texture, suffix, texture_extension):
	var texture_comps = texture.split('/')
	var texture_group = texture_comps[0]
	var texture_name = texture_comps[1]
	var path = base_texture_path + '/' + texture_group + '/' + texture_name + '/' + texture_name + '_' + suffix + texture_extension

	texture_directory.change_dir(base_texture_path)
	if(texture_directory.file_exists(path)):
		return load(path)

	return null