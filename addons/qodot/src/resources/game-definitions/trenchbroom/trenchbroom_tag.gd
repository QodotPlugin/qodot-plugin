class_name TrenchBroomTag
extends Resource

enum TagMatchType {
	TEXTURE,
	CONTENT_FLAG,
	SURFACE_FLAG,
	SURFACE_PARAM,
	CLASSNAME
}

export(String) var tag_name
export(Array, String) var tag_attributes
export(TagMatchType) var tag_match_type
export(String) var tag_pattern
export(String) var texture_name
