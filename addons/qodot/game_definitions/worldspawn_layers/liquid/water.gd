class_name WaterLayer
extends LiquidLayer

func _init().() -> void:
	buoyancy_factor = 10.0
	vertical_damping_factor = 3.0
	lateral_damping_factor = 0.3
