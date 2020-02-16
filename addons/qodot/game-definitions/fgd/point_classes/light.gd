class_name QodotLight
extends QodotEntity
tool

func update_properties():
	for child in get_children():
		remove_child(child)
		child.queue_free()

	var light_node = null

	if 'mangle' in properties:
		light_node = SpotLight.new()

		var comps = properties['mangle'].split(' ')
		var yaw = comps[0]
		var pitch = comps[1]
		light_node.rotate(Vector3.RIGHT, deg2rad(180 + int(yaw)))

		if 'angle' in properties:
			light_node.set_param(Light.PARAM_SPOT_ANGLE, (int(properties['angle'])))
	else:
		light_node = OmniLight.new()

	var light_brightness = 300
	if 'light' in properties:
		light_brightness = int(properties['light'])
		light_node.set_param(Light.PARAM_ENERGY, light_brightness / 100.0)
		light_node.set_param(Light.PARAM_INDIRECT_ENERGY, light_brightness / 100.0)

	var light_range = 1
	if 'wait' in properties:
		light_range = float(properties['wait'])

	var normalized_brightness = light_brightness / 300.0
	light_node.set_param(Light.PARAM_RANGE, 16.0 * light_range * (normalized_brightness * normalized_brightness))

	var light_attenuation = 0
	if 'delay' in properties:
		light_attenuation = int(properties['delay'])

	var attenuation = 0
	match light_attenuation:
		0:
			attenuation = 1.0
		1:
			attenuation = 0.5
		2:
			attenuation = 0.25
		3:
			attenuation = 0.15
		4:
			attenuation = 0
		5:
			attenuation = 0.9
		_:
			attenuation = 1

	light_node.set_param(Light.PARAM_ATTENUATION, attenuation)
	light_node.set_shadow(true)
	light_node.set_bake_mode(Light.BAKE_ALL)

	var light_color = Color.white
	if '_color' in properties:
		var comps = properties['_color'].split(' ')

		var red = null
		var green = null
		var blue = null

		if "." in comps[0] or "." in comps[1] or "." in comps[2]:
			red = comps[0].to_float()
			green = comps[1].to_float()
			blue = comps[2].to_float()
		else:
			red = int(comps[0]) / 255.0
			green = int(comps[1]) / 255.0
			blue = int(comps[2]) / 255.0
		light_color = Color(red, green, blue)

	light_node.set_color(light_color)

	add_child(light_node)

	if is_inside_tree():
		var tree = get_tree()
		if tree:
			var edited_scene_root = tree.get_edited_scene_root()
			if edited_scene_root:
				light_node.set_owner(edited_scene_root)
