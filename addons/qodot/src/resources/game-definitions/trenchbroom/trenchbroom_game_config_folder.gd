@tool
class_name TrenchBroomGameConfigFolder
extends Resource

## A node used to to express a set of entity definitions that can be exproted

#psuedo-button to export
@export var export_file: bool:
	get:
		return export_file # TODOConverter40 Non existent get function 
	set(new_export_file):
		if new_export_file != export_file:
			do_export_file()
func do_export_file():
	if Engine.is_editor_hint():
		if trenchbroom_games_folder.is_empty():
			print("Skipping export: No TrenchBroom games folder")
			return

		var config_folder = trenchbroom_games_folder + "/" + game_name
		var config_dir = Directory.new()

		var err = config_dir.open(config_folder)
		if err != OK:
			print("Couldn't open directory, creating...")
			err = config_dir.make_dir(config_folder)
			if err != OK:
				print("Skipping export: Failed to create directory")
				return

		if not game_config_file:
			print("Skipping export: No game config file")
			return

		if fgd_files.size() == 0:
			print("Skipping export: No FGD files")
			return

		print("Exporting TrenchBroom Game Config Folder to ", config_folder)

		var icon_path : String = config_folder + "/Icon.png"

		print("Exporting icon to ", icon_path)

		var export_icon : Image = icon.get_image()
		export_icon.resize(32, 32, Image.INTERPOLATE_LANCZOS)
		export_icon.save_png(icon_path)

		var export_config_file: TrenchBroomGameConfigFile = game_config_file.duplicate()
		export_config_file.game_name = game_name
		export_config_file.target_file = config_folder + "/GameConfig.cfg"

		export_config_file.fgd_filenames = []
		for fgd_file in fgd_files:
			export_config_file.fgd_filenames.append(fgd_file.fgd_name + ".fgd")

		export_config_file.do_export_file()

		for fgd_file in fgd_files:
			if not fgd_file is QodotFGDFile:
				print("Skipping %s: Not a valid FGD file" % [fgd_file])

			var export_fgd : QodotFGDFile = fgd_file.duplicate()
			export_fgd.target_folder = config_folder
			export_fgd.do_export_file()

		print("Export complete\n")

@export var trenchbroom_games_folder : String # (String, DIR, GLOBAL)

@export var game_name := "Qodot"
@export var icon : Texture2D
@export var game_config_file : Resource = preload("res://addons/qodot/game_definitions/trenchbroom/qodot_trenchbroom_config_file.tres")
@export var fgd_files : Array[Resource] = [ # (Array, Resource)
	preload("res://addons/qodot/game_definitions/fgd/qodot_fgd.tres")
]

func _init():
	if not icon:
		if ResourceLoader.exists("res://icon.png"):
			icon = ResourceLoader.load("res://icon.png")

func build_class_text() -> String:
	return ""
