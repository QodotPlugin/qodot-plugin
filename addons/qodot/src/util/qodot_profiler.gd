class_name QodotProfiler

var start_timestamp := 0

func _init() -> void:
	start_timestamp = OS.get_ticks_msec()

func finish() -> int:
	var end_timestamp := OS.get_ticks_msec() - start_timestamp 
	return end_timestamp
