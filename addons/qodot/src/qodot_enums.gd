class_name QodotEnums

enum Mode {
	FACE_AXES, 	# Debug visualization of raw plane data
	FACE_VERTICES,	# Debug visualization of intersecting plane vertices
	BRUSH_MESHES	# Full mesh representation with collision
}

enum Presets {
	PRESET_STANDARD,
	PRESET_VALVE,
	PRESET_QUAKE_2,
	PRESET_QUAKE_3,
	PRESET_QUAKE_3_LEGACY,
	PRESET_HEXEN_2,
	PRESET_DAIKATANA,
}

enum BitmaskFormat {
	NONE,
	QUAKE_2,
	HEXEN_2,
	DAIKATANA
}