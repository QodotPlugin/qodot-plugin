class_name QodotBuildEntitySpawns
extends QodotBuildStep

func get_name() -> String:
	return "entity_spawns"

func get_type() -> int:
	return self.Type.PER_ENTITY

func _run(context) -> Dictionary:
	var entity_idx = context['entity_idx']
	var entity_properties = context['entity_properties']

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
				node.rotate(Vector3.RIGHT, deg2rad(180 + int(yaw)))
				node.rotate(Vector3.UP, deg2rad(int(pitch)))

				if 'angle' in entity_properties:
					node.set_param(Light.PARAM_SPOT_ANGLE, (int(entity_properties['angle'])))
			else:
				node = OmniLight.new()

			var light_brightness = 300
			if 'light' in entity_properties:
				light_brightness = int(entity_properties['light'])
				node.set_param(Light.PARAM_ENERGY, light_brightness / 100.0)
				node.set_param(Light.PARAM_INDIRECT_ENERGY, light_brightness / 100.0)

			var light_range = 1
			if 'wait' in entity_properties:
				light_range = float(entity_properties['wait'])

			var normalized_brightness = light_brightness / 300.0
			node.set_param(Light.PARAM_RANGE, 16.0 * light_range * (normalized_brightness * normalized_brightness))

			var light_attenuation = 0
			if 'delay' in entity_properties:
				light_attenuation = int(entity_properties['delay'])

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

			node.set_param(Light.PARAM_ATTENUATION, attenuation)
			node.set_shadow(true)

			node.set_bake_mode(Light.BAKE_ALL)

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

		if node:
			node.name = 'entity_' + String(entity_idx) + '_' + classname

	if not node:
		return {}

	if 'origin' in entity_properties:
		node.translation = entity_properties['origin']

	return {
		'nodes': {
			'entity_spawns_node': {
				get_entity_key(entity_idx): node
			}
		}
	}
