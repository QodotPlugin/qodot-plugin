class_name QodotFGDFile
extends Resource
tool

## A node used to to express a set of entity definitions that can be exproted

#psuedo-button to export
export(bool) var export_file setget set_export_file
export(String, DIR, GLOBAL) var target_folder
export(String) var fgd_name = "Qodot"
export(Array, Resource) var entity_definitions = [
	preload("res://addons/qodot/game-definitions/fgd/solid_classes/worldspawn_solid_class.tres"),
	preload("res://addons/qodot/game-definitions/fgd/solid_classes/group_solid_class.tres"),
	preload("res://addons/qodot/game-definitions/fgd/solid_classes/detail_solid_class.tres"),
	preload("res://addons/qodot/game-definitions/fgd/solid_classes/illusionary_solid_class.tres"),
	preload("res://addons/qodot/game-definitions/fgd/solid_classes/trigger_solid_class.tres"),
	preload("res://addons/qodot/game-definitions/fgd/base_classes/light_base_class.tres"),
	preload("res://addons/qodot/game-definitions/fgd/point_classes/light_point_class.tres"),
]

func set_export_file(new_export_file = true):
	if new_export_file != export_file:
		if Engine.is_editor_hint() and get_fgd_classes().size() > 0:
			if not target_folder:
				print("Skipping export: No target folder")
				return

			if fgd_name == "":
				print("Skipping export: Empty FGD name")

			var fgd_file = target_folder + "/" + fgd_name + ".fgd"

			print("Exporting FGD to ", fgd_file)
			var file_obj = File.new()
			file_obj.open(fgd_file, File.WRITE)
			file_obj.store_string(build_class_text())
			file_obj.close()

func build_class_text() -> String:
	var res = ""
	var entities = get_fgd_classes()
	for ent in entities:
		var ent_text = ent.build_def_text()
		res += ent_text
		if ent != entities[-1]:
			res += "\n"
	return res

#This getter does a little bit of validation. Providing only an array of non-null uniquely-named entity definitions
func get_fgd_classes() -> Array:
	var res = []
	for cur_ent_def_ind in range(entity_definitions.size()):
		var cur_ent_def = entity_definitions[cur_ent_def_ind]
		if cur_ent_def == null:
			continue
		elif not (cur_ent_def is QodotFGDClass):
			printerr("Bad value in entity definition set at position %s! Not an entity defintion." % cur_ent_def_ind)
			continue
		res.append(cur_ent_def)
	return res

func get_entity_definitions() -> Dictionary:
	var res = {}
	for ent in get_fgd_classes():
		if ent is QodotFGDPointClass or ent is QodotFGDSolidClass:
			res[ent.classname] = ent
	return res
