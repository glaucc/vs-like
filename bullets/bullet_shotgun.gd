extends Area2D

var speed = Autoload.shotgun_bullet_speed
var range = Autoload.shotgun_bullet_range

var travelled_distance:int = 0

func _physics_process(delta: float) -> void:
	Autoload.bullet_speed = speed
	if Autoload.level == 3:
		speed = 1000
	elif Autoload.level == 6:
		speed = 1800
	

	var direction = Vector2.RIGHT.rotated(rotation)
	position += direction * speed * delta
	
	travelled_distance += speed * delta
	if travelled_distance > range:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	queue_free()
	if body.has_method("take_damage"):
		body.take_damage()
