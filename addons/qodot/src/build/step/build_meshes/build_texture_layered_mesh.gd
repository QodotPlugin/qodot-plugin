class_name QodotBuildTextureLayeredMesh
extends QodotBuildStep

var material: Material = null
var shader_parameter: String = ''

func _init(material: Material, shader_parameter: String) -> void:
	self.material = material
	self.shader_parameter = shader_parameter

func get_name() -> String:
	return "texture_layered_mesh"

func get_type() -> int:
	return self.Type.SINGLE

func _run(context) -> Dictionary:
	# Create TextureLayeredMesh
	var texture_layered_mesh = QodotTextureLayeredMesh.new()
	texture_layered_mesh.name = 'Mesh'
	texture_layered_mesh.set_shader_parameter(shader_parameter)
	texture_layered_mesh.set_texture_format(QodotTextureLayeredMesh.TextureFormat.RGB8)

	var new_material = self.material.duplicate()
	texture_layered_mesh.set_shader_material(new_material)

	return {
		'texture_layered_mesh': texture_layered_mesh,
		'nodes': {
			'texture_layered_mesh': texture_layered_mesh
		}
	}
