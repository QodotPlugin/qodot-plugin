extends Node

signal trigger()

func _ready():
	connect("body_entered", self, "handle_body_entered")

func handle_body_entered(body: Node):
	if body is StaticBody:
		return

	emit_signal("trigger")
