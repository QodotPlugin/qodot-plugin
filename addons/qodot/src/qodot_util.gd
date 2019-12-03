class_name QodotUtil

# General-purpose utility functions namespaced to Qodot for compatibility

const DEBUG = false

# Const-predicated print function to avoid excess log spam
static func debug_print(msg):
	if(DEBUG):
		print(msg)

# Adds the provided child to the provided object,
# set its owner to the edited scene root to make it display in the editor tree,
# then returns the child
static func add_child_editor(obj: Node, child: Node) -> Node:
	obj.add_child(child)

	if(obj.is_inside_tree()):
		var tree = obj.get_tree()
		if(tree != null):
			var edited_scene_root = tree.get_edited_scene_root()
			if(edited_scene_root != null):
				child.set_owner(edited_scene_root)

	return child
