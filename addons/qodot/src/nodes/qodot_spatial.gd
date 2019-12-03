class_name QodotSpatial, 'res://addons/qodot/icons/icon_qodot_spatial.svg'
extends Spatial

func get_class():
	return 'QodotSpatial'

func add_child_editor(child: Node) -> Node:
	add_child(child)

	if(is_inside_tree()):
		var tree = get_tree()
		if(tree != null):
			var edited_scene_root = tree.get_edited_scene_root()
			if(edited_scene_root != null):
				child.set_owner(edited_scene_root)

	return child
