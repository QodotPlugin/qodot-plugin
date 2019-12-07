class_name QodotUtil

# General-purpose utility functions namespaced to Qodot for compatibility

const DEBUG = false

# Const-predicated print function to avoid excess log spam
static func debug_print(msg):
	if(DEBUG):
		print(msg)
