class_name QuakePlaneAxes, 'res://addons/qodot/icons/icon_qodot_spatial.svg'
extends ImmediateGeometry
tool

# ImmediateGeometry  node for rendering the three-vertex representation of a QuakePlane

export(Array) var vertex_set = [Vector3.ZERO, Vector3.UP, Vector3.RIGHT]
export(Array) var indices = [0, 1, 2]
var material = SpatialMaterial.new()

func _ready():
	material_override = SpatialMaterial.new()
	material_override.flags_unshaded = true
	material_override.vertex_color_use_as_albedo = true

func _process(delta):
	clear()

	begin(1, null)
	set_color(Color.red)
	add_vertex(vertex_set[indices[0]])
	add_vertex(vertex_set[indices[1]])
	end()

	begin(1, null)
	set_color(Color.green)
	add_vertex(vertex_set[indices[0]])
	add_vertex(vertex_set[indices[2]])
	end()
