class_name QodotEntityDefinitionSet
extends Resource
tool

## A node used to to express a set of entity definitions that can be exproted

const base_text = """
@SolidClass = worldspawn : \"World Entity\" []

@SolidClass = trigger []

@baseclass color(255 255 40) = Light [
	light(integer) : \"Brightness\" : 300
	wait(integer) : \"Fade distance multiplier\" : 1
	delay(choices) : \"Attenuation\" =
	[
		0 : \"Linear falloff (Default)\"
		1 : \"Inverse distance falloff\"
		2 : \"Inverse distance squared\"
		3 : \"No falloff\"
		4 : \"Local minlight\"
		5 : \"Inverse distance squared B\"
	]
	mangle(string) : \"Spotlight angle\"
]

@PointClass size(-8 -8 -8, 8 8 8) base(Light) =
	light : \"Invisible light source\" []
"""

#psuedo-button to export
export(bool) var export_file setget set_export_file
export(String, FILE, GLOBAL, "*.fgd") var target_file
export(Array, Resource) var entity_defintions

func set_export_file(new_export_file = true):
	if new_export_file != export_file:
		if Engine.is_editor_hint() and get_entities().size() > 0:
			if not target_file:
				print("Skipping export: No target file")
			var file_obj = File.new()
			file_obj.open(target_file, File.WRITE)
			file_obj.store_string(build_def_text())
			file_obj.close()
	
func build_def_text() -> String:
	var res = base_text.strip_edges()
	for ent in get_entities():
		var ent_text = ent.build_def_text()
		res += "\n\n\n" + ent_text
	return res

#This getter does a little bit of validation. Providing only an array of non-null uniquely-named entity definitions
func get_entities() -> Array:
	var res = []
	#Remember indices so our errors can be a little more helpful
	var used_names = {"Light": -1, "light": -1, "trigger": -1, "worldspawn" : -1}
	for cur_ent_def_ind in range(entity_defintions.size()):
		var cur_ent_def = entity_defintions[cur_ent_def_ind]
		if cur_ent_def == null:
			continue
		elif not (cur_ent_def is QodotPointEntityDefinition):
			printerr("Bad value in entity definition set at position %s! Not an entity defintion." % cur_ent_def_ind)
			continue
		var ent_name = cur_ent_def.classname
		if used_names.has(ent_name):
			printerr("Entity defintion class name collision with name %s, at positions %s and %s please rename!" % [ent_name, used_names[ent_name], cur_ent_def_ind])
			continue
		used_names[ent_name] = cur_ent_def_ind
		res.append(cur_ent_def)
	return res

func get_point_entity_scene_map() -> Dictionary:
	var res = {}
	for ent in get_entities():
		if ent is QodotPointEntityDefinition:
			res[ent.classname] = ent.scene_file
	return res
