class_name QodotMap
extends QodotSpatial
tool

### Spatial node for rendering a QuakeMap resource into an entity/brush tree

# Pseudo-button for forcing a refresh after asset reimport
export(bool) var reload setget set_reload

# Pseudo-button for forcing a refresh after asset reimport
export(bool) var print_to_log

export(Script) var build_pipeline = preload('res://addons/qodot/src/build/pipeline/mesh_per_material_pipeline.gd')

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
				while child_base_script:
					var next_base = child_base_script.get_base_script()
					if next_base:
						child_base_script = next_base
					else:
						break

				if child_base_script:
					if child_base_script == QodotNode || child_base_script == QodotSpatial:
						should_remove = true

		if should_remove:
			remove_child(child)
			child.queue_free()

# Kicks off the building process
func build_map(map_file: String) -> void:
	print("\nBuilding map...\n")

	call_deferred("set_name", 'Map Build In Progress')

	var context = {
		"map_file": map_file,
		"base_texture_path": base_texture_path,
		"material_extension": material_extension,
		"texture_extension": texture_extension,
		"texture_wads": texture_wads,
		"default_material": default_material,
		"inverse_scale_factor": inverse_scale_factor
	}

	"""
	# Read entity properties and brush data
	var entity_properties_array = context['entity_properties_array']
	var brush_data_dict = context['brush_data_dict']

	# Read worldspawn properties and apply map name
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
	"""

	# Initialize thread pool
	print_log("\nInitializing Thread Pool...")
	var thread_init_profiler = QodotProfiler.new()
	var thread_pool = QodotThreadPool.new()
	thread_pool.set_max_threads(max_build_threads)
	thread_pool.set_bucket_size(build_bucket_size)
	context['thread_pool'] = thread_pool
	var thread_init_duration = thread_init_profiler.finish()
	print_log("Done in " + String(thread_init_duration * 0.001) + " seconds.\n")

	# Run build steps
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
		for result_key in results:
			var result = results[result_key]
			if result:
				if not result_key in build_order:
					build_order.append(result_key)
				for data_key in result:
					if data_key == 'nodes':
						var nodes = result[data_key]
						add_context_nodes_recursive(context, data_key, nodes)
					else:
						if data_key in context:
							for result_key in result[data_key]:
								var data = result[data_key][result_key]
								context[data_key][result_key] = data
						else:
							context[data_key] = result[data_key]
		var job_duration = job_profiler.finish()
		print_log("Done in " + String(job_duration * 0.001) + " seconds.\n")

	# Cleanup thread pool
	print_log("Cleaning up thread pool...")
	var thread_cleanup_profiler = QodotProfiler.new()
	context.erase('thread_pool')
	thread_pool.finish()
	var thread_cleanup_duration = thread_cleanup_profiler.finish()
	print_log("Done in " + String(thread_cleanup_duration * 0.001) + " seconds...\n")

	# Finalize build
	call_deferred("finalize_build", context, build_order)

func add_context_nodes_recursive(context: Dictionary, context_key: String, nodes: Dictionary):
	for node_key in nodes:
		var node = nodes[node_key]
		if node is Dictionary:
			add_context_nodes_recursive(context[context_key]['children'], node_key, node)
		else:
			if not context_key in context:
				context[context_key] = {
					'children': {}
				}

			context[context_key]['children'][node_key] = {
				'node': node,
				'children': {}
			}

			if 'node' in context[context_key]:
				context[context_key]['node'].add_child(node)


# Queues a build step for execution
func queue_build_step(context: Dictionary, build_step: QodotBuildStep):
	var build_step_type = build_step.get_type()

	var thread_pool = context['thread_pool']

	var step_context = {}
	for build_step_param_name in build_step.get_build_params():
		if not build_step_param_name in context:
			print("Error: Requested parameter " + build_step_param_name + " not present in context for build step " + build_step.get_name())

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

	add_results_to_scene(context['nodes'])

func run_finalize_step(context: Dictionary, build_step: QodotBuildStep) -> void:
	var build_step_name = build_step.get_name()

	var step_context = {}
	for build_step_param_name in build_step.get_finalize_params():
		if not build_step_param_name in context:
			print("Error: Requested parameter " + build_step_param_name + " not present in context for build step " + build_step.get_name())
		step_context[build_step_param_name] = context[build_step_param_name]

	print_log("Finalizing " + build_step.get_name() + "...")
	var finalize_profiler = QodotProfiler.new()
	var finalize_result = build_step._finalize(step_context)
	if 'nodes' in finalize_result:
		add_context_nodes_recursive(context, 'nodes', finalize_result['nodes'])
	var finalize_duration = finalize_profiler.finish()
	print_log("Done in " + String(finalize_duration * 0.001) + " seconds.\n")

func add_results_to_scene(nodes: Dictionary) -> void:
	print_log("Adding nodes to scene...")
	var node_add_profiler = QodotProfiler.new()
	for node_key in nodes['children']:
		var node_data = nodes['children'][node_key]
		var node = node_data['node']
		add_child(node)
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
	if not node.get_parent() is QodotTextureLayeredMesh:
		node.set_owner(new_owner)

	for child in node.get_children():
		recursive_set_owner(child, new_owner)
