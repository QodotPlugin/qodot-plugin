class_name QodotDependencies

static func check_dependencies() -> void:
	if not Engine.class_exists("Qodot"):
		printerr("You need to be build the engine with the Qodot module!!! check: https://github.com/EIRTeam/libqodot-cpp/")
