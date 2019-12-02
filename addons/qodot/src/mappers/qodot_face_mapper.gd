class_name QodotFaceMapper

# Determine whether the given face should spawn a visual mesh
static func should_spawn_face_mesh(plane: QuakePlane, parent_brush: QuakeBrush, grandparent_entity: QuakeEntity) -> bool:
	# Don't spawn a mesh if the face is textured with SKIP
	if(plane.texture.find('skip') > -1):
		return false

	return true
