class_name QodotPrinter

# Convenience class for printing human-readable Array and Dictionary types

static func print_typed(msg):
	print(_to_str(msg))

static func _to_str(msg, indent = ""):
	var msg_str = ""

	if msg is Array:
		msg_str = _to_str_array(msg, indent)
	elif msg is Dictionary:
		msg_str = _to_str_dict(msg, indent)
	elif typeof(msg) == TYPE_OBJECT:
		msg_str = msg.get_class()
	else:
		msg_str = String(msg)

	return msg_str

static func _to_str_array(array: Array, indent = ""):
	var inner_indent = indent + "\t"

	var msg_string = "[\n"

	for idx in range(0, array.size()):
		msg_string += inner_indent + String(idx) + ": " + _to_str(array[idx], inner_indent) + "\n"

	msg_string += indent + "]\n"

	return msg_string

static func _to_str_dict(dict: Dictionary, indent = ""):
	var inner_indent = indent + "\t"

	var msg_string = "{\n"

	for key in dict:
		msg_string += inner_indent + String(key) + ": " + _to_str(dict[key], inner_indent) + "\n"

	msg_string += indent + "}\n"

	return msg_string
