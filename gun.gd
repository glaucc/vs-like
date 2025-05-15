extends Area2D

func _physics_process(delta: float) -> void:
	var enemies_in_range = get_overlapping_bodies()
	if enemies_in_range.size() == 0:
		return

	var closest_enemy = enemies_in_range[0]
	var closest_dist = global_position.distance_to(closest_enemy.global_position)
	for enemy in enemies_in_range:
		var dist = global_position.distance_to(enemy.global_position)
		if dist < closest_dist:
			closest_enemy = enemy
			closest_dist = dist
	
	#AIM
	look_at(closest_enemy.global_position)


func shoot():
	const BULLET = preload("res://bullet.tscn")
	var new_bullet = BULLET.instantiate()
	new_bullet.global_position = %ShootingPoint.global_position
	new_bullet.global_rotation = %ShootingPoint.global_rotation
	%ShootingPoint.add_child(new_bullet)


func _on_timer_timeout() -> void:
	shoot()
