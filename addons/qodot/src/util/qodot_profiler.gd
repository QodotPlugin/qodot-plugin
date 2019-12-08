class_name QodotProfiler

var start_timestamp = null

func _init():
	start_timestamp = OS.get_ticks_msec()

func finish():
	var end_timestamp = OS.get_ticks_msec()
	return end_timestamp - start_timestamp
