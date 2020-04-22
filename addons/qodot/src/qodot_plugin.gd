class_name QodotPlugin
extends EditorPlugin
tool

var map_import_plugin : QuakeMapImportPlugin = null
var palette_import_plugin : QuakePaletteImportPlugin = null
var wad_import_plugin : QuakeWadImportPlugin = null

var qodot_map_control: Control = null
var qodot_map_progress_bar: Control = null
var edited_object_ref: WeakRef = weakref(null)

var http_request: HTTPRequest = null

func get_plugin_name() -> String:
	return "Qodot"

func handles(object: Object) -> bool:
	return object is QodotMap

func edit(object: Object) -> void:
	edited_object_ref = weakref(object)

func make_visible(visible: bool) -> void:
	if qodot_map_control:
		qodot_map_control.set_visible(visible)

	if qodot_map_progress_bar:
		qodot_map_progress_bar.set_visible(visible)

func _enter_tree() -> void:
	# Project settings
	setup_project_settings()

	# Import plugins
	map_import_plugin = QuakeMapImportPlugin.new()
	palette_import_plugin = QuakePaletteImportPlugin.new()
	wad_import_plugin = QuakeWadImportPlugin.new()

	add_import_plugin(map_import_plugin)
	add_import_plugin(palette_import_plugin)
	add_import_plugin(wad_import_plugin)

	# QodotMap button
	qodot_map_control = create_qodot_map_control()
	qodot_map_control.set_visible(false)
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, qodot_map_control)

	qodot_map_progress_bar = create_qodot_map_progress_bar()
	qodot_map_progress_bar.set_visible(false)
	add_control_to_container(EditorPlugin.CONTAINER_PROPERTY_EDITOR_BOTTOM, qodot_map_progress_bar)

	# Download libraries
	http_request = HTTPRequest.new()
	http_request.use_threads = true
	add_child(http_request)

	QodotDependencies.check_dependencies(http_request)

func _exit_tree() -> void:
	remove_import_plugin(map_import_plugin)
	remove_import_plugin(palette_import_plugin)
	remove_import_plugin(wad_import_plugin)
	map_import_plugin = null
	palette_import_plugin = null
	wad_import_plugin = null

	remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, qodot_map_control)
	qodot_map_control.queue_free()
	qodot_map_control = null

	remove_control_from_container(EditorPlugin.CONTAINER_PROPERTY_EDITOR_BOTTOM, qodot_map_progress_bar)
	qodot_map_progress_bar.queue_free()
	qodot_map_progress_bar = null

	remove_child(http_request)
	http_request.queue_free()

func setup_project_settings() -> void:
	try_add_project_setting('qodot/textures/normal_pattern', TYPE_STRING, QodotTextureLoader.PBR_SUFFIX_PATTERNS[QodotTextureLoader.PBRSuffix.NORMAL])
	try_add_project_setting('qodot/textures/metallic_pattern', TYPE_STRING, QodotTextureLoader.PBR_SUFFIX_PATTERNS[QodotTextureLoader.PBRSuffix.METALLIC])
	try_add_project_setting('qodot/textures/roughness_pattern', TYPE_STRING, QodotTextureLoader.PBR_SUFFIX_PATTERNS[QodotTextureLoader.PBRSuffix.ROUGHNESS])
	try_add_project_setting('qodot/textures/emission_pattern', TYPE_STRING, QodotTextureLoader.PBR_SUFFIX_PATTERNS[QodotTextureLoader.PBRSuffix.EMISSION])
	try_add_project_setting('qodot/textures/ao_pattern', TYPE_STRING, QodotTextureLoader.PBR_SUFFIX_PATTERNS[QodotTextureLoader.PBRSuffix.AO])
	try_add_project_setting('qodot/textures/depth_pattern', TYPE_STRING, QodotTextureLoader.PBR_SUFFIX_PATTERNS[QodotTextureLoader.PBRSuffix.DEPTH])

func try_add_project_setting(name: String, type: int, value, info: Dictionary = {}) -> void:
	if not ProjectSettings.has_setting(name):
		add_project_setting(name, type, value, info)

func add_project_setting(name: String, type: int, value, info: Dictionary = {}) -> void:
	ProjectSettings.set(name, value)

	var info_dict := info.duplicate()
	info_dict['name'] = name
	info_dict['type'] = type

	ProjectSettings.add_property_info(info_dict)
	ProjectSettings.set_initial_value(name, value)

func create_qodot_map_control() -> Control:
	var separator = VSeparator.new()

	var icon = TextureRect.new()
	icon.texture = preload("res://addons/qodot/icons/icon_qodot_spatial.svg")
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var quick_build_button = ToolButton.new()
	quick_build_button.text = "Quick Build"
	quick_build_button.connect("pressed", self, "qodot_map_quick_build")

	var full_build_button = ToolButton.new()
	full_build_button.text = "Full Build"
	full_build_button.connect("pressed", self, "qodot_map_full_build")

	var unwrap_uv2_button = ToolButton.new()
	unwrap_uv2_button.text = "Unwrap UV2"
	unwrap_uv2_button.connect("pressed", self, "qodot_map_unwrap_uv2")

	var control = HBoxContainer.new()
	control.add_child(separator)
	control.add_child(icon)
	control.add_child(quick_build_button)
	control.add_child(full_build_button)
	control.add_child(unwrap_uv2_button)

	return control

func create_qodot_map_progress_bar() -> Control:
	var progress_label = Label.new()
	progress_label.name = "ProgressLabel"
	progress_label.align = Label.ALIGN_LEFT
	progress_label.valign = Label.VALIGN_CENTER

	var progress_bar = ProgressBar.new()
	progress_bar.name = "ProgressBar"
	progress_bar.percent_visible = false
	progress_bar.min_value = 0.0
	progress_bar.max_value = 1.0
	progress_bar.rect_min_size.y = 30
	progress_bar.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	progress_bar.add_child(progress_label)
	progress_label.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	progress_label.margin_top = -9
	progress_label.margin_left = 3

	return progress_bar


func qodot_map_quick_build() -> void:
	var edited_object = edited_object_ref.get_ref()
	if not edited_object:
		return

	if not edited_object is QodotMap:
		return

	edited_object.should_add_children = true
	edited_object.should_set_owners = false

	set_qodot_map_control_disabled(true)
	edited_object.connect("build_progress", self, "qodot_map_build_progress")
	edited_object.connect("build_complete", self, "qodot_map_build_complete", [edited_object])
	edited_object.connect("build_failed", self, "qodot_map_build_complete", [edited_object])

	edited_object.verify_and_build()

func qodot_map_full_build() -> void:
	var edited_object = edited_object_ref.get_ref()
	if not edited_object:
		return

	if not edited_object is QodotMap:
		return

	edited_object.should_add_children = true
	edited_object.should_set_owners = true

	set_qodot_map_control_disabled(true)
	edited_object.connect("build_progress", self, "qodot_map_build_progress")
	edited_object.connect("build_complete", self, "qodot_map_build_complete", [edited_object])
	edited_object.connect("build_failed", self, "qodot_map_build_complete", [edited_object])

	edited_object.verify_and_build()

func qodot_map_unwrap_uv2() -> void:
	var edited_object = edited_object_ref.get_ref()
	if not edited_object:
		return

	if not edited_object is QodotMap:
		return

	set_qodot_map_control_disabled(true)
	edited_object.connect("unwrap_uv2_complete", self, "qodot_map_build_complete", [edited_object])

	edited_object.unwrap_uv2()

func set_qodot_map_control_disabled(disabled: bool) -> void:
	if not qodot_map_control:
		return

	for child in qodot_map_control.get_children():
		if child is ToolButton:
			child.set_disabled(disabled)

func qodot_map_build_progress(step: String, progress: float) -> void:
	var progress_label = qodot_map_progress_bar.get_node("ProgressLabel")
	qodot_map_progress_bar.value = progress
	progress_label.text = step.capitalize()

func qodot_map_build_complete(qodot_map: QodotMap) -> void:
	var progress_label = qodot_map_progress_bar.get_node("ProgressLabel")
	progress_label.text = "Build Complete"

	set_qodot_map_control_disabled(false)

	if qodot_map.is_connected("build_progress", self, "qodot_map_build_progress"):
		qodot_map.disconnect("build_progress", self, "qodot_map_build_progress")

	if qodot_map.is_connected("build_complete", self, "qodot_map_build_complete"):
		qodot_map.disconnect("build_complete", self, "qodot_map_build_complete")

	if qodot_map.is_connected("build_failed", self, "qodot_map_build_complete"):
		qodot_map.disconnect("build_failed", self, "qodot_map_build_complete")
