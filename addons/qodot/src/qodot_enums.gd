class_name QodotEnums

enum MapMode {
	FACE_AXES, 		# Debug visualization of raw plane data
	FACE_VERTICES,	# Debug visualization of intersecting plane vertices
	BRUSH_MESHES	# Full mesh representation with collision
}

enum MapFormat {
	STANDARD,
	VALVE,
	QUAKE_2,
	QUAKE_3,
	QUAKE_3_LEGACY,
	HEXEN_2,
	DAIKATANA,
}

enum BitmaskFormat {
	NONE,
	QUAKE_2,
	HEXEN_2,
	DAIKATANA
}