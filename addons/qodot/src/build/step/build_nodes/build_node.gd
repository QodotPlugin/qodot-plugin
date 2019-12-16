class_name QodotBuildNode
extends QodotBuildStep

var internal_name: String = "node"
var readable_name: String = "Node"
var node_type = null
var attach_path: Array = []

func _init(internal_name: String, readable_name: String, node_type = QodotNode, attach_path: Array = []) -> void:
	self.internal_name = internal_name
	self.readable_name = readable_name
	self.node_type = node_type
	self.attach_path = attach_path

func get_name() -> String:
	return internal_name.to_lower()

func get_type() -> int:
	return self.Type.SINGLE

func _run(context) -> Dictionary:
	var node = node_type.new()
	node.name = readable_name
	node.set_meta("_edit_lock_", true)

	var attach_dict = {
		'nodes': {}
	}

	var candidate_dict = attach_dict['nodes']
	for path_element in attach_path:
		candidate_dict[path_element] = {}
		candidate_dict = candidate_dict[path_element]
	candidate_dict[internal_name] = node

	return attach_dict
