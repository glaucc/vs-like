extends Area2D

var is_taken = false

func _on_body_entered(body: Node2D) -> void:
	if !is_taken:
		Autoload.add_coins(1)
		is_taken = true
		reset_physics_interpolation()
		queue_free()
