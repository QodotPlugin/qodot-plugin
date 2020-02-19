class_name QuakeWadFile
extends Resource

export(Dictionary) var textures : Dictionary

func _init(textures: Dictionary) -> void:
	self.textures = textures
