class_name QodotUtil

const DEBUG = false
	
static func debug_print(msg):
	if(DEBUG):
		print(msg)

static func add_child_editor(obj, child):
	obj.add_child(child)
	if(obj.is_inside_tree()):
		var tree = obj.get_tree()
		if(tree != null):
			var edited_scene_root = tree.get_edited_scene_root()
			if(edited_scene_root != null):
				child.set_owner(edited_scene_root)
	return child
