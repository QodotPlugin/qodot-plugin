class_name QodotEntityDefintionSet
extends QodotSpatial
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
export(bool) var export_file_button setget set_export_file_button
export(String, FILE, GLOBAL, "*.fgd") var target_export_file


func set_export_file_button(new_export_file_button = true):
	if new_export_file_button != export_file_button:
		if Engine.is_editor_hint() and get_entities().size() > 0:
			if not target_export_file:
				print("Skipping export: No target file")
			var file_obj = File.new()
			file_obj.open(target_export_file, File.WRITE)
			file_obj.store_string(build_def_text())
			file_obj.close()
	
func build_def_text() -> String:
	var res = base_text.strip_edges()
	for ent in get_entities():
		var ent_text = ent.build_def_text()
		res += "\n\n\n" + ent_text
	return res

func get_entities() -> Array:
	var res = []
	var used_names = {"Light": true, "light": true, "trigger": true, "worldspawn" : true}
	#I'll search the children recursively using this queue
	#in case you wanted to use like other nodes for grouping or whatever, I don't know
	var search_queue = get_children().duplicate()
	while search_queue.size() > 0:
		var cur_child = search_queue.pop_front()
		if cur_child is QodotEntityDefinition:
			var ent_name = cur_child.determine_entity_class_name()
			if used_names.has(ent_name):
				printerr("Class name collision on %s, please rename!" % ent_name)
				return []
			res.append(cur_child)
		for c in cur_child.get_children():
			search_queue.append(c)
	return res

func get_entity_scenes() -> Dictionary:
	var res = {}
	for ent in get_entities():
		res[ent.determine_entity_class_name()] = ent.scene_file
	return res
