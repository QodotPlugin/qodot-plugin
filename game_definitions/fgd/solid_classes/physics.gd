@tool
class_name PhysicsEntity
extends RigidDynamicBody3D

@export var properties: Dictionary :
	get:
		return properties # TODOConverter40 Non existent get function 
	set(new_properties):
		if(properties != new_properties):
			properties = new_properties
			update_properties()

func update_properties():
	if 'velocity' in properties:
		linear_velocity = properties['velocity']

	if 'mass' in properties:
		mass = properties.mass


func use():
	bounce()

func bounce():
	linear_velocity.y = 10
