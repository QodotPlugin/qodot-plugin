## Defines a new game in Trenchbroom to express a set of entity definitions and editor defaults.
class_name TrenchBroomGameConfig
extends Resource
tool

## Button to export new folder to the Trenchbroom Games Path
export(bool) var export_file : bool setget set_export_file

## The /games folder in either your Trenchbroom installation or your OS user data folder.
export(String, DIR, GLOBAL) var trenchbroom_games_folder : String

## Name of the game in Trenchbroom's game list
export(String) var game_name := "Qodot"

## Icon for Trenchbroom's game list
export(Texture) var icon : Texture

## Array of FGD resources to include with this game
export(Array, Resource) var fgd_files : Array = [
	preload("res://addons/qodot/game_definitions/fgd/qodot_fgd.tres")
]

## Per-brush patterns to apply editor hints
export(Array, Resource) var brush_tags : Array = []
## Per-texture patterns to apply editor hints
export(Array, Resource) var face_tags : Array = []

## Map-wide bitflags toggleable for each face
export(Array, Resource) var face_attrib_surface_flags : Array = []
## Map-wide bitflags toggleable for each brush
export(Array, Resource) var face_attrib_content_flags : Array = []

## Private variable for storing fgd names, used in build_class_text()
var fgd_filenames : Array = []

## Private default .cfg contents, read more at: https://trenchbroom.github.io/manual/latest/#game_configuration_files 
var base_text: String = """{
	version: 3,
	name: "%s",
	icon: "Icon.png",
	"fileformats": [
		{ "format": "Standard", "initialmap": "initial_standard.map" },
		{ "format": "Valve", "initialmap": "initial_valve.map" },
		{ "format": "Quake2", "initialmap": "initial_quake2.map" },
		{ "format": "Quake3" },
		{ "format": "Quake3 (legacy)" },
		{ "format": "Hexen2" },
		{ "format": "Daikatana" }
	],
	"filesystem": {
		"searchpath": ".",
		"packageformat": { "extension": "pak", "format": "idpak" }
	},
	"textures": {
		"package": { "type": "directory", "root": "textures" },
		"format": { "extensions": ["bmp", "exr", "hdr", "jpeg", "jpg", "png", "tga", "webp"], "format": "image" },
		"attribute": "_tb_textures"
	},
	"entities": {
		"definitions": [ %s ],
		"defaultcolor": "0.6 0.6 0.6 1.0",
		"modelformats": [ "mdl", "md2", "md3", "bsp", "dkm" ]
	},
	"tags": {
		"brush": [
			%s
		],
		"brushface": [
			%s
		]
	},
	"faceattribs": {
		"surfaceflags": [
			%s
		],
		"contentflags": [
			%s
		]
	}
}
"""

## Initalize .cfg icon if none is set.
func _init() -> void:
	if not icon:
		if ResourceLoader.exists("res://icon.png"):
			icon = ResourceLoader.load("res://icon.png")

## Exports folder and files to Trenchbroom games folder
func set_export_file(new_export_file : bool = true) -> void:
	# When boolean button is pressed
	if new_export_file != export_file:
		if Engine.is_editor_hint():
			# If no folder location is defined, return
			if not trenchbroom_games_folder:
				print("Skipping export: No TrenchBroom games folder")
				return
			# Create config folder name by combining games folder with the game name as a directory
			var config_folder = trenchbroom_games_folder + "/" + game_name
			var config_dir = Directory.new()
			var err = config_dir.open(config_folder)
			if err != OK:
				print("Couldn't open directory, creating...")
				# Check that it was possible to make this directory in the target location
				err = config_dir.make_dir(config_folder)
				if err != OK:
					# TODO: Use alternate userdata path if the dir was unsuccessful
					print("Skipping export: Failed to create directory")
					return
			# If there is no FGD loaded, return
			if fgd_files.size() == 0:
				print("Skipping export: No FGD files")
				return
			print("Exporting TrenchBroom Game Config Folder to ", config_folder)
			
			# Icon
			var icon_path : String = config_folder + "/Icon.png"
			print("Exporting icon to ", icon_path)
			var export_icon : Image = icon.get_data()
			export_icon.resize(32, 32, Image.INTERPOLATE_LANCZOS)
			export_icon.save_png(icon_path)
			# .cfg
			var export_config_file: Dictionary = {}
			export_config_file.game_name = game_name
			fgd_filenames = []
			for fgd_file in fgd_files:
				fgd_filenames.append(fgd_file.fgd_name + ".fgd")
				print("Exported %s" % [fgd_file.fgd_name + ".fgd"])
			export_config_file.target_file = config_folder + "/GameConfig.cfg"
			print("Exporting TrenchBroom Game Config File to ", export_config_file.target_file)
			var file_obj := File.new()
			file_obj.open(export_config_file.target_file, File.WRITE)
			file_obj.store_string(build_class_text())
			file_obj.close()
			# FGDs
			for fgd_file in fgd_files:
				if not fgd_file is QodotFGDFile:
					print("Skipping %s: Not a valid FGD file" % [fgd_file])
					continue
				var export_fgd : QodotFGDFile = fgd_file.duplicate()
				export_fgd.target_folder = config_folder
				export_fgd.set_export_file(true)
			print("Export complete\n")

## Replaces format strings with variable contents into base_text, returns complete .cfg as String
func build_class_text() -> String:
	var fgd_filename_str := ""
	for fgd_filename in fgd_filenames:
		fgd_filename_str += "\"%s\"" % fgd_filename
		if fgd_filename != fgd_filenames[-1]:
			fgd_filename_str += ", "

	var brush_tags_str = parse_tags(brush_tags)
	var face_tags_str = parse_tags(face_tags)
	var surface_flags_str = parse_flags(face_attrib_surface_flags)
	var content_flags_str = parse_flags(face_attrib_content_flags)

	return base_text % [
		game_name,
		fgd_filename_str,
		brush_tags_str,
		face_tags_str,
		surface_flags_str,
		content_flags_str
	]

## Matches tag key enum to the String name used in .cfg
static func get_match_key(tag_match_type: int) -> String:
	var tag_keys = {
		0: "texture",
		1: "contentflag",
		2: "surfaceflag",
		3: "surfaceparm",
		4: "classname"
	}
	return tag_keys[tag_match_type]

## Converts brush, face, and attribute tags into a .cfg-usable String
func parse_tags(tags: Array) -> String:
	var tags_str := ""
	for brush_tag in tags:
		tags_str += "{\n"
		tags_str += "\t\t\t\t\"name\": \"%s\",\n" % brush_tag.tag_name

		var attribs_str := ""
		for brush_tag_attrib in brush_tag.tag_attributes:
			attribs_str += "\"%s\"" % brush_tag_attrib
			if brush_tag_attrib != brush_tag.tag_attributes[-1]:
				attribs_str += ", "

		tags_str += "\t\t\t\t\"attribs\": [ %s ],\n" % attribs_str

		tags_str += "\t\t\t\t\"match\": \"%s\",\n" % get_match_key(brush_tag.tag_match_type)
		tags_str += "\t\t\t\t\"pattern\": \"%s\"" % brush_tag.tag_pattern

		if brush_tag.texture_name != "":
			tags_str += ",\n"
			tags_str += "\t\t\t\t\"texture\": \"%s\"" % brush_tag.texture_name

		tags_str += "\n"

		tags_str += "\t\t\t}"

		if brush_tag != tags[-1]:
			tags_str += ","

	return tags_str

## Converts array of flags to .cfg String
func parse_flags(flags: Array) -> String:
	var flags_str := ""

	for attrib_flag in flags:
		flags_str += "{\n"
		flags_str += "\t\t\t\t\"name\": \"%s\",\n" % attrib_flag.attrib_name
		flags_str += "\t\t\t\t\"description\": \"%s\"\n" % attrib_flag.attrib_description
		flags_str += "\t\t\t}"
		if attrib_flag != flags[-1]:
			flags_str += ","
	return flags_str
