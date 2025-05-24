extends Camera2D

var shake_strength := 0.0
var shake_decay := 5.0

func shake(duration: float, strength: float):
	shake_strength = strength
	await get_tree().create_timer(duration).timeout
	shake_strength = 0.0
	offset = Vector2.ZERO

func _process(delta: float) -> void:
	if shake_strength > 0.0:
		offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake_strength
		shake_strength = lerp(shake_strength, 0.0, delta * shake_decay)
