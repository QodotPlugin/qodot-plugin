class_name QodotSpatial, 'res://addons/qodot/icons/icon_qodot_spatial.svg'
extends Spatial

func get_class():
	return 'QodotSpatial'

func add_child_editor(child):
	add_child(child)

	if not is_inside_tree():
		print("Not inside tree")
		return

	var tree = get_tree()

	if not tree:
		print("Invalid tree")
		return

	var edited_scene_root = tree.get_edited_scene_root()
	if not edited_scene_root:
		print("Invalid edited scene root")
		return

	child.set_owner(edited_scene_root)

func _ready():
	# Prevent QodotMap children from inheriting its tool mode process callbacks in the editor
	if Engine.is_editor_hint():
		set_process(false)
		set_physics_process(false)
