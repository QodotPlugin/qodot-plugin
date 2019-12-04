class_name QodotBrushMapper

# Determine whether the given brush should create a set of visual face meshes
static func should_spawn_brush_mesh(brush: QuakeBrush, parent_entity: QuakeEntity) -> bool:
	# Don't spawn collision if the brush is textured entirely with CLIP
	var is_clip = true
	for face in brush.faces:
		if(face.texture.find('clip') == -1):
			is_clip = false

	if(is_clip):
		return false

	# Classname-specific behavior
	if('classname' in parent_entity.properties):
		# Don't spawn collision for trigger brushes
		return parent_entity.properties['classname'].find('trigger') == -1

	# Default to true for entities with empty classnames
	return true

# Determine whether the given .map classname should create a collision object
static func should_spawn_brush_collision(brush: QuakeBrush, parent_entity: QuakeEntity) -> bool:
	return true

# Create and return a CollisionObject for the given .map classname
static func spawn_brush_collision_object(brush: QuakeBrush, parent_entity: QuakeEntity) -> CollisionObject:
	var node = null

	# Use an Area for trigger brushes
	if('classname' in parent_entity.properties):
		if(parent_entity.properties['classname'].find('trigger') > -1):
			return Area.new()

	return StaticBody.new()
