class_name QodotBuildMeshes
extends QodotBuildStep

# Determine whether the given brush should create a set of visual face meshes
func should_spawn_brush_mesh(entity_properties: Dictionary, brush: QuakeBrush) -> bool:
	if(brush.is_clip_brush()):
		return false

	# Classname-specific behavior
	if('classname' in entity_properties):
		# Don't spawn collision for trigger brushes
		return entity_properties['classname'].findn('trigger') == -1

	# Default to true for entities with empty classnames
	return true

# Determine whether the given face should spawn a visual mesh
func should_spawn_face_mesh(entity_properties: Dictionary, brush: QuakeBrush, face: QuakeFace) -> bool:
	# Don't spawn a mesh if the face is textured with SKIP
	if(face.texture.findn('skip') > -1):
		return false

	return true
