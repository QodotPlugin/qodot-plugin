class_name TrenchBroomTag
extends Resource

enum TagMatchType {
	TEXTURE,
	CONTENT_FLAG,
	SURFACE_FLAG,
	SURFACE_PARAM,
	CLASSNAME
}

export(String) var tag_name : String
export(Array, String) var tag_attributes : Array
export(TagMatchType) var tag_match_type : int
export(String) var tag_pattern : String
export(String) var texture_name : String
