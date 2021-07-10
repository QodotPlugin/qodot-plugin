class_name TrenchBroomGameConfigFolder
extends Resource
tool

## A node used to to express a set of entity definitions that can be exproted

#psuedo-button to export
export(bool) var export_file : bool setget set_export_file
export(String, DIR, GLOBAL) var trenchbroom_games_folder : String

export(String) var game_name := "Qodot"
export(Texture) var icon : Texture
export(Resource) var game_config_file : Resource = preload("res://addons/qodot/game_definitions/trenchbroom/qodot_trenchbroom_config_file.tres")
export(Array, Resource) var fgd_files : Array = [
	preload("res://addons/qodot/game_definitions/fgd/qodot_fgd.tres")
]

func _init() -> void:
	if not icon:
		if ResourceLoader.exists("res://icon.png"):
			icon = ResourceLoader.load("res://icon.png")

func set_export_file(new_export_file : bool = true) -> void:
	if new_export_file != export_file:
		if Engine.is_editor_hint():
			if not trenchbroom_games_folder:
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

			var export_icon : Image = icon.get_data()
			export_icon.resize(32, 32, Image.INTERPOLATE_LANCZOS)
			export_icon.save_png(icon_path)

			var export_config_file: TrenchBroomGameConfigFile = game_config_file.duplicate()
			export_config_file.game_name = game_name
			export_config_file.target_file = config_folder + "/GameConfig.cfg"

			export_config_file.fgd_filenames = []
			for fgd_file in fgd_files:
				export_config_file.fgd_filenames.append(fgd_file.fgd_name + ".fgd")

			export_config_file.set_export_file(true)

			for fgd_file in fgd_files:
				if not fgd_file is QodotFGDFile:
					print("Skipping %s: Not a valid FGD file" % [fgd_file])

				var export_fgd : QodotFGDFile = fgd_file.duplicate()
				export_fgd.target_folder = config_folder
				export_fgd.set_export_file(true)

			print("Export complete\n")

func build_class_text() -> String:
	return ""
