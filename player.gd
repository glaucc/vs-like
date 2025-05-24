extends CharacterBody2D

signal health_depleted

var health = 100.0 * Autoload.player_health_percent
var max_health = 100.0 * Autoload.player_health_percent
var speed = 150 * Autoload.player_speed_percent
var DAMAGE_RATE = 100.0 * Autoload.player_armor_percent

#mobile movement support
var touch_start_pos := Vector2.ZERO
var touch_current_pos := Vector2.ZERO
var touching := false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_start_pos = event.position
			touch_current_pos = event.position
			touching = true
		else:
			touching = false
			velocity = Vector2.ZERO

	elif event is InputEventScreenDrag:
		touch_current_pos = event.position


func _physics_process(delta: float) -> void:
	#Movement
	var direction := Vector2.ZERO

	if touching:
		direction += (touch_current_pos - touch_start_pos).normalized()

	# Keyboard movement (WASD, arrows)
	direction += Input.get_vector("move_left", "move_right", "move_up", "move_down")

	# Normalize to prevent faster diagonal movement
	if direction.length() > 1:
		direction = direction.normalized()

	velocity = direction * speed
	if !touching and velocity.length() > 0.1:
		velocity = velocity.move_toward(Vector2.ZERO, 200 * delta)
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
		
		#VFX
		self.modulate = Color(1, 0.3, 0.3) # Flash red
		await get_tree().create_timer(0.05).timeout
		self.modulate = Color(1, 1, 1, 1) # Reset
		
		%ProgressBar.value = health
		%ProgressBar.max_value = max_health
		if health <= 0.0:
			health_depleted.emit()
