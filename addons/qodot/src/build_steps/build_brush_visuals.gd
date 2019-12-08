class_name QodotBuildBrushVisuals
extends QodotBuildStep

func get_name() -> String:
	return "brush_visuals"

func get_type() -> int:
	return self.Type.PER_BRUSH

func get_build_params() -> Array:
	return ['material_dict', 'inverse_scale_factor']

func _run(context) -> Array:
	var entity_idx = context['entity_idx']
	var brush_idx = context['brush_idx']
	var entity_properties = context['entity_properties']
	var brush_data = context['brush_data']
	var material_dict = context['material_dict']
	var inverse_scale_factor = context['inverse_scale_factor']

	var brush_visuals = _build_visuals(entity_idx, brush_idx, entity_properties, brush_data, material_dict, inverse_scale_factor)
	return ["nodes", [entity_idx, brush_idx], brush_visuals]

func _build_visuals(entity_idx: int, brush_idx: int, entity_properties: Dictionary, brush_data: Array, material_dict: Dictionary, inverse_scale_factor: float):
	var map_reader = QuakeMapReader.new()
	var brush = map_reader.create_brush(brush_data)

	if not should_spawn_brush_mesh(entity_properties, brush):
		return []

	return []

# Determine whether the given brush should create a set of visual face meshes
static func should_spawn_brush_mesh(entity_properties: Dictionary, brush: QuakeBrush) -> bool:
	# Don't spawn collision if the brush is textured entirely with CLIP
	var is_clip = true
	for face in brush.faces:
		if(face.texture.find('clip') == -1):
			is_clip = false

	if(is_clip):
		return false

	# Classname-specific behavior
	if('classname' in entity_properties):
		# Don't spawn collision for trigger brushes
		return entity_properties['classname'].find('trigger') == -1

	# Default to true for entities with empty classnames
	return true
