extends Area2D

var speed = Autoload.shotgun_bullet_speed
var range = Autoload.shotgun_bullet_range

var travelled_distance:int = 0

func _physics_process(delta: float) -> void:
	Autoload.bullet_speed = speed
	

	var direction = Vector2.RIGHT.rotated(rotation)
	position += direction * speed * delta
	
	travelled_distance += speed * delta
	if travelled_distance > range:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		var damage = Autoload.shotgun_base_damage * Autoload.player_damage_percent
		var is_crit = randf() < Autoload.crit_chance
		if is_crit:
			damage *= Autoload.crit_multiplier
		body.take_damage(damage, is_crit)
	
	queue_free()
