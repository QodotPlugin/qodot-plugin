extends CharacterBody3D

@export var properties: Dictionary :
	get:
		return properties # TODOConverter40 Non existent get function 
	set(new_properties):
		if properties != new_properties:
			properties = new_properties
			update_properties()

var base_transform: Transform3D
var offset_transform: Transform3D
var target_transform: Transform3D

var speed := 1.0



func update_properties() -> void:
	if 'translation' in properties:
		offset_transform.origin = properties.translation

	if 'rotation' in properties:
		offset_transform.basis = offset_transform.basis.rotated(Vector3.RIGHT, properties.rotation.x)
		offset_transform.basis = offset_transform.basis.rotated(Vector3.UP, properties.rotation.y)
		offset_transform.basis = offset_transform.basis.rotated(Vector3.FORWARD, properties.rotation.z)

	if 'scale' in properties:
		offset_transform.basis = offset_transform.basis.scaled(properties.scale)

	if 'speed' in properties:
		speed = properties.speed

func _process(delta: float) -> void:
	transform = transform.interpolate_with(target_transform, speed * delta)

func _init():
	base_transform = transform
	target_transform = base_transform

func use() -> void:
	play_motion()

func play_motion() -> void:
	target_transform = base_transform * offset_transform

func reverse_motion() -> void:
	target_transform = base_transform
