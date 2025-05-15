extends Area2D

var is_taken = false

func _on_body_entered(body: Node2D) -> void:
	if !is_taken:
		Autoload.add_coins(20)
		is_taken = true
		queue_free()
