class_name TrenchBroomGameConfigFile
extends Resource
tool

export(bool) var export_file : bool setget set_export_file
export(String, FILE, GLOBAL, "*.cfg") var target_file : String

export(String) var game_name := "Qodot"

export(Array, Resource) var brush_tags : Array = []
export(Array, Resource) var face_tags : Array = []
export(Array, Resource) var face_attrib_surface_flags : Array = []
export(Array, Resource) var face_attrib_content_flags : Array = []

export(Array, String) var fgd_filenames : Array = []

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

func set_export_file(new_export_file : bool = true) -> void:
	if new_export_file != export_file:
		if not Engine.is_editor_hint():
			return

		if not target_file:
			print("Skipping export: No target file")
			return

		print("Exporting TrenchBroom Game Config File to ", target_file)
		var file_obj := File.new()
		file_obj.open(target_file, File.WRITE)
		file_obj.store_string(build_class_text())
		file_obj.close()

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

static func get_match_key(tag_match_type: int) -> String:
	var tag_keys = {
		0: "texture",
		1: "contentflag",
		2: "surfaceflag",
		3: "surfaceparm",
		4: "classname"
	}

	return tag_keys[tag_match_type]

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
