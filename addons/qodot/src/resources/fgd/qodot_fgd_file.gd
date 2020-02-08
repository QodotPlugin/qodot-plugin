class_name QodotFGDFile
extends Resource
tool

## A node used to to express a set of entity definitions that can be exproted

#psuedo-button to export
export(bool) var export_file setget set_export_file
export(String, FILE, GLOBAL, "*.fgd") var target_file
export(Array, Resource) var entity_defintions

func set_export_file(new_export_file = true):
	if new_export_file != export_file:
		if Engine.is_editor_hint() and get_fgd_classes().size() > 0:
			if not target_file:
				print("Skipping export: No target file")
			print("Exporting FGD to ", target_file)
			var file_obj = File.new()
			file_obj.open(target_file, File.WRITE)
			file_obj.store_string(build_class_text())
			file_obj.close()
			print("Export complete")

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
	for cur_ent_def_ind in range(entity_defintions.size()):
		var cur_ent_def = entity_defintions[cur_ent_def_ind]
		if cur_ent_def == null:
			continue
		elif not (cur_ent_def is QodotFGDClass):
			printerr("Bad value in entity definition set at position %s! Not an entity defintion." % cur_ent_def_ind)
			continue
		res.append(cur_ent_def)
	return res

func get_point_entity_scene_map() -> Dictionary:
	var res = {}
	for ent in get_fgd_classes():
		if ent is QodotFGDPointClass:
			res[ent.classname] = ent.scene_file
	return res
