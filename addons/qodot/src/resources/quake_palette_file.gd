class_name QuakePaletteFile
extends Resource

export(PoolColorArray) var colors : PoolColorArray

func _init(colors) -> void:
	self.colors = colors
