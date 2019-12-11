class_name QodotMap
extends QodotSpatial
tool

### Spatial node for rendering a QuakeMap resource into an entity/brush tree

# Pseudo-button for forcing a refresh after asset reimport
export(bool) var reload setget set_reload

# Pseudo-button for forcing a refresh after asset reimport
export(bool) var print_to_log

export(Script) var build_pipeline = QodotMeshPerMaterialPipeline

# Factor to scale the .map file's quake units down by
# (16 is a best-effort conversion from Quake 3 units to metric)
export(float) var inverse_scale_factor = 16.0

# .map Resource to auto-load when updating the map from the editor
# (Works around references being held and preventing refresh on reimport)
export(String, FILE, '*.map') var map_file

# Base search path for textures specified in the .map file
export(String, DIR) var base_texture_path = 'res://textures'

# File extensions appended to textures specified in the .map file
export(String) var texture_extension = '.png'
export(Array, String, FILE, "*.wad") var texture_wads = []

# Materials
export(String) var material_extension = '.tres'
export (SpatialMaterial) var default_material

# Threads
export(int) var max_build_threads = 4
export(int) var build_bucket_size = 4

# Instances
var build_thread = Thread.new()
var build_profiler = null

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

			build_profiler = QodotProfiler.new()
			build_thread.start(self, "build_map", map_file)

func print_log(msg):
	if(print_to_log):
		QodotPrinter.print_typed(msg)

func _exit_tree():
	if(build_thread.is_active()):
		build_thread.wait_to_finish()

# Clears any existing children
func clear_map():
	for child in get_children():
		var should_remove = false

		var child_script = child.get_script()
		if child_script:
			if child_script == QodotNode || child_script == QodotSpatial:
				should_remove = true
			else:
				var child_base_script = child_script.get_base_script()
				if child_base_script:
					if child_base_script == QodotNode || child_base_script == QodotSpatial:
						should_remove = true

		if should_remove:
			remove_child(child)
			child.queue_free()

# Kicks off the building process
func build_map(map_file: String) -> void:
	print("\nBuilding map...\n")

	var context = build_pipeline.initialize_context(
		map_file,
		base_texture_path,
		material_extension,
		texture_extension,
		texture_wads,
		default_material
	)

	context['inverse_scale_factor'] = inverse_scale_factor

	if 'entity_properties' in context:
		var entity_properties = context['entity_properties']
		if entity_properties.size() > 0:
			var worldspawn_properties = entity_properties[0]
			if 'message' in worldspawn_properties:
				call_deferred("set_name", worldspawn_properties['message'])

	print_log("\nInitializing Thread Pool...")
	var thread_init_profiler = QodotProfiler.new()
	var thread_pool = QodotThreadPool.new()
	thread_pool.set_max_threads(max_build_threads)
	thread_pool.set_bucket_size(build_bucket_size)
	context['thread_pool'] = thread_pool
	var thread_init_duration = thread_init_profiler.finish()
	print_log("Done in " + String(thread_init_duration * 0.001) + " seconds.\n")

	var build_order = []

	var build_steps = build_pipeline.get_build_steps()
	for build_step_idx in range(0, build_steps.size()):
		var build_step = build_steps[build_step_idx]
		var step_name = build_step.get_name()

		queue_build_step(context, build_step)

		print_log("Building " + build_step.get_name() + "...")
		var job_profiler = QodotProfiler.new()
		thread_pool.start_thread_jobs()
		var results = yield(thread_pool, "jobs_complete")
		context[step_name] = []
		build_order.append(step_name)
		for result_idx in results:
			var result = results[result_idx]
			if result:
				context[step_name].append(result)
		var job_duration = job_profiler.finish()
		print_log("Done in " + String(job_duration * 0.001) + " seconds.\n")

	print_log("Cleaning up thread pool...")
	var thread_cleanup_profiler = QodotProfiler.new()
	context.erase('thread_pool')
	thread_pool.finish()
	var thread_cleanup_duration = thread_cleanup_profiler.finish()
	print_log("Done in " + String(thread_cleanup_duration * 0.001) + " seconds...\n")

	call_deferred("finalize_build", context, build_order)


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

func finalize_build(context, build_order):
	build_thread.wait_to_finish()

	for build_step in build_pipeline.get_build_steps():
		if build_step.get_wants_finalize():
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

func run_finalize_step(context: Dictionary, build_step: QodotBuildStep) -> void:
	var build_step_name = build_step.get_name()

	var step_context = {}
	for build_step_param_name in build_step.get_finalize_params():
		if not build_step_param_name in context:
			print("Error: Requested parameter not present in context")
		step_context[build_step_param_name] = context[build_step_param_name]

	print_log("Finalizing " + build_step.get_name() + "...")
	var finalize_profiler = QodotProfiler.new()
	build_step._finalize(step_context)
	var finalize_duration = finalize_profiler.finish()
	print_log("Done in " + String(finalize_duration * 0.001) + " seconds.\n")

func add_results_to_scene(results) -> void:
	print_log("Adding nodes to scene...")
	var node_add_profiler = QodotProfiler.new()
	for result in results:
		var filtered_results = []
		for result_data in result:
			var result_type = result_data[0]
			if result_type == "nodes":
				filtered_results.append(result_data)

		for result_data in filtered_results:
			var attach_path = result_data[1]
			var attach_nodes = result_data[2]

			var attach_target = get_node(attach_path)
			for node in attach_nodes:
				attach_target.add_child(node)
	var node_add_duration = node_add_profiler.finish()
	print_log("Done in " + String(node_add_duration * 0.001) + " seconds.\n")

	add_nodes_to_editor_tree()

func add_nodes_to_editor_tree():
	print_log("Adding nodes to editor tree...")
	var node_editor_profiler = QodotProfiler.new()
	var edited_scene_root = get_tree().get_edited_scene_root()
	add_children_to_editor(edited_scene_root)
	var node_editor_duration = node_editor_profiler.finish()
	print_log("Done in " + String(node_editor_duration * 0.001) + " seconds.\n")

	build_complete()

# Build completion handler
func build_complete() -> void:
	var build_duration = build_profiler.finish()
	print("Build complete after " + String(build_duration * 0.001) + " seconds.\n")

func add_children_to_editor(edited_scene_root) -> void:
	for child in get_children():
		recursive_set_owner(child, edited_scene_root)

func recursive_set_owner(node, new_owner) -> void:
	node.set_owner(new_owner)
	for child in node.get_children():
		recursive_set_owner(child, new_owner)
