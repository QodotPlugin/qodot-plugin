class_name QuakeMapImportPlugin
extends EditorImportPlugin
tool

# Quake .map import plugin

func get_importer_name():
	return 'qodot.map'

func get_visible_name():
	return 'Quake Map'

func get_recognized_extensions():
	return ['map']

func get_save_extension():
	return 'tres'

func get_resource_type():
	return 'QuakeMap'

func get_preset_count():
	return QodotEnums.Presets.size()

# Only supports standard-format Quake 1 maps for now,
# but any extensions should be implemented using presets
func get_preset_name(preset):
	match preset:
		QodotEnums.Presets.PRESET_STANDARD:
			return 'Standard'
		QodotEnums.Presets.PRESET_VALVE:
			return 'Valve'
		QodotEnums.Presets.PRESET_QUAKE_2:
			return 'Quake 2'
		QodotEnums.Presets.PRESET_QUAKE_3:
			return 'Quake 3'
		QodotEnums.Presets.PRESET_QUAKE_3_LEGACY:
			return 'Quake 3 (Legacy)'
		QodotEnums.Presets.PRESET_HEXEN_2:
			return 'Hexen 2'
		QodotEnums.Presets.PRESET_DAIKATANA:
			return 'Daikatana'
		_:
			return 'Unknown'

func get_import_options(preset):
	var valve_uvs = false
	var bitmask_format = QodotEnums.BitmaskFormat.NONE

	match preset:
		QodotEnums.Presets.PRESET_VALVE:
			valve_uvs = true
		QodotEnums.Presets.PRESET_QUAKE_2:
			bitmask_format = QodotEnums.BitmaskFormat.QUAKE_2
		QodotEnums.Presets.PRESET_QUAKE_3:
			bitmask_format = QodotEnums.BitmaskFormat.QUAKE_2
		QodotEnums.Presets.PRESET_QUAKE_3_LEGACY:
			bitmask_format = QodotEnums.BitmaskFormat.QUAKE_2
		QodotEnums.Presets.PRESET_HEXEN_2:
			bitmask_format = QodotEnums.BitmaskFormat.HEXEN_2
		QodotEnums.Presets.PRESET_DAIKATANA:
			bitmask_format = QodotEnums.BitmaskFormat.DAIKATANA

	return [
		{
			'name': 'valve_texture_coordinates',
			'default_value': valve_uvs
		},
		{
			'name': 'bitmask_format',
			'default_value': bitmask_format,
			'property_hint': PROPERTY_HINT_ENUM,
			'hint_string': "None,Quake 2,Hexen 2,Daikatana"
		}
	]

func get_option_visibility(option, options):
	return true

func import(source_file, save_path, options, r_platform_variants, r_gen_files):

	print('Importing ', source_file, ' to be saved in ', save_path, ' with options ', options)
	var file = File.new()
	QodotUtil.debug_print('Opening file')
	var err = file.open(source_file, File.READ)
	if err != OK:
		QodotUtil.debug_print(['Error opening file: ', err])
		return err

	var valve_uvs = options['valve_texture_coordinates']
	var bitmask_format = options['bitmask_format']

	var quake_map_reader = QuakeMapReader.new()
	var quake_map: QuakeMap = quake_map_reader.read_map_file(file, valve_uvs, bitmask_format)

	if(QodotUtil.DEBUG):
		for entity in quake_map.entities:
			QodotUtil.debug_print(entity)
			for brush in entity.brushes:
				QodotUtil.debug_print(['\t', brush])
				for plane in brush.planes:
					QodotUtil.debug_print(['\t\t', plane])

	file.close()

	var save_path_str = '%s.%s' % [save_path, get_save_extension()]

	QodotUtil.debug_print(['Saving ', quake_map, ' to ', save_path_str])
	var result = ResourceSaver.save(save_path_str, quake_map)
	QodotUtil.debug_print(['ResourceSaver result: ', result])

	# Attempt to forcefully reload the map asset
	quake_map = null
	quake_map = load(save_path_str)

	return result
