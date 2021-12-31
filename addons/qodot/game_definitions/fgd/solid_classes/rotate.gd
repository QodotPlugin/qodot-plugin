class_name QodotRotateEntity
extends CharacterBody3D

@export var properties: Dictionary :
	get:
		return properties # TODOConverter40 Non existent get function 
	set(new_properties):
		if(properties != new_properties):
			properties = new_properties
			update_properties()

var rotate_axis := Vector3.UP
var rotate_speed := 360.0

func update_properties():
	if 'axis' in properties:
		rotate_axis = properties['axis']

	if 'speed' in properties:
		rotate_speed = properties['speed']

func _ready() -> void:
	update_properties()

func _process(delta: float) -> void:
	rotate(rotate_axis, deg2rad(rotate_speed * delta))
