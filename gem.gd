extends Area2D

@export var score_value: int = 7

func _on_body_entered(body: Node2D) -> void:
	if body.name == "player":
		Autoload.score += score_value
		queue_free()
