class_name QodotBuildEntitySpawns
extends QodotBuildStep

func get_name() -> String:
	return "entity_spawns"

func get_type() -> int:
	return self.Type.PER_ENTITY

func get_build_params() -> Array:
	return ['inverse_scale_factor']

func _run(context):
	var entity_idx = context['entity_idx']
	var entity_properties = context['entity_properties']
	var inverse_scale_factor = context['inverse_scale_factor']

	var node = null

	if('classname' in entity_properties):
		var classname = entity_properties['classname']
		if classname.substr(0, 5) == 'func_':
			node = null
		elif classname.substr(0, 5) == 'light':
			if 'mangle' in entity_properties:
				node = SpotLight.new()

				var comps = entity_properties['mangle'].split(' ')
				var yaw = comps[0]
				var pitch = comps[1]
				node.rotate(node.global_transform.basis.x, deg2rad(int(pitch)))
				node.rotate(node.global_transform.basis.y, deg2rad(180 + int(yaw)))

				if 'angle' in entity_properties:
					node.set_param(Light.PARAM_SPOT_ANGLE, (int(entity_properties['angle'])))
			else:
				node = OmniLight.new()

			var light_brightness = 300
			if 'light' in entity_properties:
				light_brightness = int(entity_properties['light'])
			node.set_param(Light.PARAM_ENERGY, light_brightness / 2560.0)

			var light_range = 1
			if 'wait' in entity_properties:
				light_range = float(entity_properties['wait'])

			var light_attenuation = 0
			if 'delay' in entity_properties:
				light_attenuation = int(entity_properties['delay'])

			var attenuation = 0
			match light_attenuation:
				0:
					attenuation = 1
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

			var range_multiplier = 1
			if attenuation == 0:
				range_multiplier = 0.001
			else:
				range_multiplier = attenuation

			node.set_param(Light.PARAM_RANGE, 8.8 / light_range / range_multiplier)
			node.set_param(Light.PARAM_ATTENUATION, attenuation)

			var light_color = Color.white
			if '_color' in entity_properties:
				var comps = entity_properties['_color'].split(' ')
				var red = int(comps[0]) / 255.0
				var green = int(comps[1]) / 255.0
				var blue = int(comps[2]) / 255.0
				light_color = Color(red, green, blue)
			node.set_color(light_color)
		else:
			match classname:
				'worldspawn':
					node = null
				'trigger':
					node = null
				_:
					node = Position3D.new()
					if 'angle' in entity_properties:
						node.rotation.y = deg2rad(180 + entity_properties['angle'])

	if not node:
		return null

	return ["nodes", get_entity_attach_path(entity_idx), [node] if node else []]
