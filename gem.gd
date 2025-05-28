extends Area2D



func _on_body_entered(body: Node2D) -> void:
	if body.name == "player":
		Autoload.score += 7
		reset_physics_interpolation()
		queue_free()
