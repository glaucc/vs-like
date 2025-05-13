extends CharacterBody2D

signal health_depleted

var health = 100.0
var max_health = 100.0
const SPEED = 50
const DAMAGE_RATE = 100.0

func _physics_process(delta: float) -> void:
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * 600
	move_and_slide()
	
	
	
	if velocity.length() > 0.0:
		pass
		#walk animation
	else:
		pass
		#idle animation
	
	var overlapping_mobs = %HurtBox.get_overlapping_bodies()
	if overlapping_mobs.size() > 0:
		health -= overlapping_mobs.size() * DAMAGE_RATE * delta
		%ProgressBar.value = health
		%ProgressBar.max_value = max_health
		if health <= 0.0:
			health_depleted.emit()
	
