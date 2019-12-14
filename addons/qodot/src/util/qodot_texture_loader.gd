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
	texture_wads: Array,
	default_material = null
	) -> Dictionary:
	var texture_wad_resources = []
	for texture_wad_path in texture_wads:
		var texture_wad = load(texture_wad_path) as QuakeWadFile
		if texture_wad and not texture_wad in texture_wad_resources:
			texture_wad_resources.append(texture_wad)

	var texture_materials = {}
	for texture in texture_list:
		texture_materials[texture] = get_material(
			texture,
			base_texture_path,
			material_extension,
			texture_extension,
			texture_wad_resources,
			default_material
		)
	return texture_materials

func get_material(
	texture_name: String,
	base_texture_path: String,
	material_extension: String,
	texture_extension: String,
	texture_wad_resources: Array,
	default_material = null
	):
	var material = null

	if(texture_name != TEXTURE_EMPTY):
		# Autoload material if it exists
		var material_path = base_texture_path + '/' + texture_name + material_extension

		if not material_path in material_dict and texture_directory.file_exists(material_path):
			var loaded_material: Material = load(material_path)
			if loaded_material:
				material_dict[material_path] = loaded_material

		if material_path in material_dict:
			# If material already exists, use it
			material = material_dict[material_path]
		else:
			# Load albedo texture if it exists
			var texture_path = base_texture_path + '/' + texture_name + texture_extension

			var texture = null

			if(texture_directory.file_exists(texture_path)):
				texture = load(texture_path)

			if not texture:
				for texture_wad in texture_wad_resources:
					var texture_name_lower = texture_name.to_lower()
					if texture_name_lower in texture_wad.textures:
						texture = texture_wad.textures[texture_name_lower]
						break

			if texture:
				if default_material:
					material = default_material.duplicate()
				else:
					material = SpatialMaterial.new()

				material.set_texture(SpatialMaterial.TEXTURE_ALBEDO, texture)

				var pbr_textures = get_pbr_textures(base_texture_path, texture_name, texture_extension)
				for pbr_suffix in PBR_SUFFICES:
					if(pbr_suffix != null):
						var tex = pbr_textures[pbr_suffix[0]]
						if(tex != null):
							var enable_prop = pbr_suffix[2] if pbr_suffix.size() >= 3 else null
							if(enable_prop):
								material.set(enable_prop, true)

							var texture_enum = pbr_suffix[1]
							material.set_texture(texture_enum, tex)

				material_dict[material_path] = material

	return material

# PBR texture fetching
func get_pbr_textures(base_texture_path, texture, texture_extension):
	var pbr_textures = {}
	for suffix in PBR_SUFFICES:
		var suffix_string = suffix[0]
		pbr_textures[suffix_string] = get_pbr_texture(base_texture_path, texture, suffix_string, texture_extension)
	return pbr_textures

func create_pbr_material(
	albedo_texture: Texture,
	base_texture_path: String,
	texture_name: String,
	texture_extension: String,
	default_material: SpatialMaterial = null
	) -> SpatialMaterial:
	var material = null

	if default_material:
		material = default_material.duplicate()
	else:
		material = SpatialMaterial.new()

	material.set_texture(SpatialMaterial.TEXTURE_ALBEDO, albedo_texture)

	var pbr_textures = get_pbr_textures(base_texture_path, texture_name, texture_extension)
	for pbr_suffix in PBR_SUFFICES:
		if(pbr_suffix != null):
			var tex = pbr_textures[pbr_suffix[0]]
			if(tex != null):
				var enable_prop = pbr_suffix[2] if pbr_suffix.size() >= 3 else null
				if(enable_prop):
					material.set(enable_prop, true)

				var texture_enum = pbr_suffix[1]
				material.set_texture(texture_enum, tex)

	return material

func get_pbr_texture(base_texture_path, texture, suffix, texture_extension):
	var texture_comps = texture.split('/')

	if texture_comps.size() == 0:
		return null

	var texture_string = ''
	for comp in texture_comps:
		texture_string += '/' + comp

	var path = base_texture_path + texture_string + '/' + texture_comps[-1] + '_' + suffix + texture_extension

	if(texture_directory.file_exists(path)):
		return load(path)

	return null
