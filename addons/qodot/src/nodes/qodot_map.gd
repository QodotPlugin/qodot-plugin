class_name QodotMap
extends QodotSpatial
tool

### Spatial node for rendering a QuakeMap resource into an entity/brush tree

# Pseudo-button for forcing a refresh after asset reimport
export(bool) var reload setget set_reload

# Pseudo-button for forcing a refresh after asset reimport
export(bool) var print_to_log

# Map file format
export(QodotEnums.MapFormat) var map_format = QodotEnums.MapFormat.STANDARD

# Factor to scale the .map file's quake units down by
# (16 is a best-effort conversion from Quake 3 units to metric)
export(float) var inverse_scale_factor = 16.0

# .map Resource to auto-load when updating the map from the editor
# (Works around references being held and preventing refresh on reimport)
export(String, FILE, '*.map') var map_file

# Base search path for textures specified in the .map file
export(String, DIR) var base_texture_path = 'res://textures'

# File extensions appended to textures specified in the .map file
export(String) var material_extension = '.tres'
export(String) var texture_extension = '.png'

# Materials
export (SpatialMaterial) var default_material

func get_build_steps():
	return [
		QodotBuildEntities.new(),
		QodotBuildBrushes.new(),
		QodotBuildBrushCollision.new(),
		#QodotBuildBrushFaceAxes.new(),
		#QodotBuildBrushFaceVertices.new(),
		QodotBuildBrushFaceMeshes.new()
	]

# Threads
export(int) var max_build_threads = 4
export(int) var build_bucket_size = 4

# Instances
var texture_loader = QodotTextureLoader.new()

var build_thread = Thread.new()

var build_start_timestamp = 0

## Setters
func set_reload(new_reload):
	if reload != new_reload:
		if Engine.is_editor_hint():
			if build_thread.is_active():
				print("Skipping reload: Build in progress")
				return

			clear_map()

			if not map_file:
				print("Skipping reload: No map file")
				return

			build_start_timestamp = OS.get_ticks_msec()
			build_thread.start(self, "build_map", map_file)

func print_log(msg):
	if(print_to_log):
		QodotPrinter.print_typed(msg)

# Returns whether a given format uses Valve-style UVs
func get_valve_uvs(map_format: int):
	return map_format == QodotEnums.MapFormat.VALVE

# Returns the bimask format for a given map format
func get_bitmask_format(map_format: int):
	match map_format:
		QodotEnums.MapFormat.QUAKE_2:
			return QodotEnums.BitmaskFormat.QUAKE_2
		QodotEnums.MapFormat.QUAKE_3:
			return QodotEnums.BitmaskFormat.QUAKE_2
		QodotEnums.MapFormat.QUAKE_3_LEGACY:
			return QodotEnums.BitmaskFormat.QUAKE_2
		QodotEnums.MapFormat.HEXEN_2:
			return QodotEnums.BitmaskFormat.HEXEN_2
		QodotEnums.MapFormat.DAIKATANA:
			return QodotEnums.BitmaskFormat.DAIKATANA

	return QodotEnums.BitmaskFormat.NONE

func _exit_tree():
	build_thread.wait_to_finish()

# Clears any existing children
func clear_map():
	for child in get_children():
		if child.get_script() == QodotEntity || child.get_script() == QodotBrush:
			remove_child(child)
			child.queue_free()

# Queues a build step for execution
func queue_build_step(context: Dictionary, build_step: QodotBuildStep):
	var build_step_type = build_step.get_type()

	var thread_pool = context['thread_pool']

	var step_context = {}
	for build_step_param_name in build_step.get_build_params():
		if not build_step_param_name in context:
			print("Error: Requested parameter not present in context")

		if build_step_param_name == "thread_pool":
			print("Error: Build steps cannot require the thread pool as a parameter")

		step_context[build_step_param_name] = context[build_step_param_name]

	print_log("Queueing " + build_step.get_name() + " for building...")

	if build_step_type == QodotBuildStep.Type.SINGLE:
		thread_pool.add_thread_job(build_step, "_run", step_context)
	else:
		var entity_properties_array = context['entity_properties_array']
		for entity_idx in range(0, entity_properties_array.size()):
			var entity_context = step_context.duplicate()
			entity_context['entity_idx'] = entity_idx
			entity_context['entity_properties'] = entity_properties_array[entity_idx]

			if build_step_type == QodotBuildStep.Type.PER_ENTITY:
				thread_pool.add_thread_job(build_step, "_run", entity_context)
			elif build_step_type == QodotBuildStep.Type.PER_BRUSH:
				var brush_data_dict = context['brush_data_dict']
				for brush_idx in brush_data_dict[entity_idx]:
					var brush_context = entity_context.duplicate()
					brush_context['brush_idx'] = brush_idx
					brush_context['brush_data'] = brush_data_dict[entity_idx][brush_idx]
					thread_pool.add_thread_job(build_step, "_run", brush_context)

	print_log("Done.\n")

func run_finalize_step(context: Dictionary, build_step: QodotBuildStep) -> void:
	var build_step_name = build_step.get_name()

	var step_context = {}
	for build_step_param_name in build_step.get_finalize_params():
		if not build_step_param_name in context:
			print("Error: Requested parameter not present in context")
		step_context[build_step_param_name] = context[build_step_param_name]

	print_log("Finalizing " + build_step.get_name() + "...")
	build_step._finalize(step_context)
	print_log("Done.\n")

# Kicks off the building process
func build_map(map_file: String) -> void:
	print("\nBuilding map...")

	print_log("Parsing map file...")
	var map_reader = QuakeMapReader.new()
	var parsed_map = map_reader.parse_map(map_file, get_valve_uvs(map_format), get_bitmask_format(map_format))
	print_log("Done.\n")

	var entity_properties_array = parsed_map[0]
	var brush_data_dict = parsed_map[1]

	var worldspawn_properties = entity_properties_array[0]
	var entity_count = entity_properties_array.size()

	print_log("Entity Count: " + String(entity_count))

	var brush_count = 0
	for entity_idx in brush_data_dict:
		brush_count += brush_data_dict[entity_idx].size()

	print_log("Brush Count: " + String(brush_count) + "\n")

	print_log("Worldspawn Properties:")
	print_log(worldspawn_properties)

	if 'message' in worldspawn_properties:
		call_deferred("set_name", worldspawn_properties['message'])

	print_log("\nLoading textures...")
	var texture_list = map_reader.get_texture_list(brush_data_dict)
	var material_dict = texture_loader.load_texture_materials(texture_list, base_texture_path, material_extension, texture_extension, default_material)
	print_log("Done.\n")

	print_log("Map textures:")
	print_log(texture_list)

	print_log("\nInitializing Thread Pool...")
	var thread_pool = QodotThreadPool.new()
	thread_pool.set_max_threads(max_build_threads)
	thread_pool.set_bucket_size(build_bucket_size)
	print_log("Done.\n")

	var context = {
		"thread_pool": thread_pool,
		"entity_properties_array": entity_properties_array,
		"brush_data_dict": brush_data_dict,
		"material_dict": material_dict,
		"inverse_scale_factor": inverse_scale_factor
	}

	var build_order = []

	var build_steps = get_build_steps()
	for build_step_idx in range(0, build_steps.size()):
		var build_step = build_steps[build_step_idx]
		var step_name = build_step.get_name()

		queue_build_step(context, build_step)

		print_log("Building " + build_step.get_name() + "...")
		thread_pool.start_thread_jobs()
		var results = yield(thread_pool, "jobs_complete")
		context[step_name] = []
		build_order.append(step_name)
		for result_idx in results:
			var result = results[result_idx]
			context[step_name].append(result)
		print_log("Done.\n")

	print_log("Cleaning up thread pool...")
	context.erase('thread_pool')
	thread_pool.finish()
	print_log("Done...\n")

	call_deferred("finalize_build", context, build_order)

func finalize_build(context, build_order):
	build_thread.wait_to_finish()

	for build_step in get_build_steps():
		if build_step.wants_finalize():
			run_finalize_step(context, build_step)

	context.erase('entity_properties_array')
	context.erase('brush_data_dict')
	context.erase('material_dict')
	context.erase('inverse_scale_factor')

	print_log("Preparing results...")
	var results = []
	for build_step_name in build_order:
		results.append(context[build_step_name])
	print_log("Done.\n")

	add_results_to_scene(results)

func add_results_to_scene(results) -> void:
	print_log("Adding nodes to scene...")
	for result in results:
		var filtered_results = []
		for result_data in result:
			var result_type = result_data[0]
			if result_type == "nodes":
				filtered_results.append(result_data)

		filtered_results.sort_custom(self, "sort_result_data")

		for result_data in filtered_results:
			var attach_path = result_data[1]
			var attach_nodes = result_data[2]

			var attach_target = self
			while(attach_path.size() > 0):
				var attach_idx = attach_path.pop_front()
				if attach_target.get_child_count() > attach_idx:
					attach_target = attach_target.get_child(attach_idx)

			for node in attach_nodes:
				attach_target.add_child(node)
	print_log("Done.\n")

	add_nodes_to_editor_tree()

func add_nodes_to_editor_tree():
	print_log("Adding nodes to editor tree...")
	var edited_scene_root = get_tree().get_edited_scene_root()
	add_children_to_editor(edited_scene_root)
	print_log("Done.\n")

	build_complete()

# Build completion handler
func build_complete() -> void:
	var build_end_timestamp = OS.get_ticks_msec()
	var build_duration = build_end_timestamp - build_start_timestamp
	print("Build complete after " + String(build_duration * 0.001) + " seconds.\n")

func sort_result_data(a, b) -> bool:
	var attach_path_a = a[1]
	var attach_path_b = b[1]

	var depth = 0
	while true:
		if depth >= attach_path_a.size():
			return false

		if depth >= attach_path_b.size():
			return true

		if attach_path_a[depth] == attach_path_b[depth]:
			depth += 1
		else:
			return attach_path_a[depth] < attach_path_b[depth]

	return false

func add_children_to_editor(edited_scene_root) -> void:
	for child in get_children():
		recursive_set_owner(child, edited_scene_root)

func recursive_set_owner(node, new_owner) -> void:
	node.set_owner(new_owner)
	for child in node.get_children():
		recursive_set_owner(child, new_owner)
