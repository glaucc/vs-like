# Player.gd
extends CharacterBody2D

signal health_depleted
signal revived # Signal for when player revives

# Initialize these in _update_stats to ensure they are current
var health: float
var max_health: float
var speed: float
var DAMAGE_RATE: float # Or rename to player_defense_modifier

#mobile movement support
var touch_start_pos := Vector2.ZERO
var touch_current_pos := Vector2.ZERO
var touching := false

var can_vibrate := true # Android
var is_invulnerable := false # NEW: for extra life invulnerability

func _ready() -> void:
	_update_stats() # Call it here to initialize stats
	%ProgressBar.max_value = max_health
	%ProgressBar.value = health
	health = max_health

	# Connect to signals if Autoload emits them on stat changes
	# (Optional, but good for dynamic updates if stats change mid-game outside of upgrades)
	# Autoload.connect("player_stats_changed", Callable(self, "_update_stats"))

func _unhandled_input(event: InputEvent) -> void:
	var screen_width = get_viewport_rect().size.x
	var move_side_left = not Autoload.controls_flipped

	if event is InputEventScreenTouch:
		var is_left = event.position.x < screen_width * 0.5

		if move_side_left != is_left:
			return  # Touch is not on the movement side

		if event.pressed:
			touch_start_pos = event.position
			touch_current_pos = event.position
			touching = true
		else:
			touching = false
			velocity = Vector2.ZERO

	elif event is InputEventScreenDrag:
		var is_left = event.position.x < screen_width * 0.5
		if move_side_left != is_left:
			return  # Drag is not on the movement side
		touch_current_pos = event.position


func _physics_process(delta: float) -> void:
	# Movement
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
	
	if velocity.x < 0:
		%PixelBall.flip_h = true
	elif velocity.x > 0:
		%PixelBall.flip_h = false
	
	move_and_slide()


	if velocity.length() > 0.0:
		pass
		#walk animation
	else:
		pass
		#idle animation

	# Player takes damage from overlapping mobs
	if not is_invulnerable: # Only take damage if not invulnerable
		var overlapping_mobs = %HurtBox.get_overlapping_bodies()
		if overlapping_mobs.size() > 0:
			health -= overlapping_mobs.size() * DAMAGE_RATE * delta # DMG_RATE is effectively player's defense
			
			if Autoload.vibration_enabled and can_vibrate:
				Input.vibrate_handheld(
					Autoload.vibration_duration_ms,  # Customizable duration (e.g., 200ms)
					Autoload.vibration_amplitude     # Optional: strength (0.0 to 1.0, Godot 4.4+)
				)
				can_vibrate = false
				%VibrationCooldownTimer.start(Autoload.vibration_cooldown_sec) # Assuming you add a Timer node named VibrationCooldownTimer

			# VFX
			self.modulate = Color(1, 0.3, 0.3) # Flash red
			await get_tree().create_timer(0.05).timeout
			self.modulate = Color(1, 1, 1, 1) # Reset
			
			%ProgressBar.value = health
			%ProgressBar.max_value = max_health

			if health <= 0.0:
				# Direct health_depleted emission, Gameplay will handle UI
				health_depleted.emit()
				set_physics_process(false) # Stop player movement/damage
				visible = false # Hide player
				print("Player health depleted! Signalling Game Over.")
		
	# Health Regeneration
	if Autoload.health_regen > 0.0:
		health += Autoload.health_regen * delta
		health = min(health, max_health) # Ensure health doesn't go above max_health
	
	# Update the progress bar after potential health regeneration
	%ProgressBar.value = health
	%ProgressBar.max_value = max_health


# Function to update player stats based on Autoload values
func _update_stats():
	max_health = 200.0 * Autoload.player_health_percent
	speed = 150 * Autoload.player_speed_percent
	DAMAGE_RATE = 100.0 * Autoload.player_armor_percent
	
	health = health + (max_health - %ProgressBar.max_value) 
	health = min(health, max_health) 
	
	%ProgressBar.max_value = max_health
	%ProgressBar.value = health
	print("Player stats updated: Max Health=", max_health, ", Speed=", speed, ", DamageRate(Defense)=", DAMAGE_RATE)

# Function to handle actual revival (called by Gameplay button)
func revive_player():
	health = max_health # Full health
	is_invulnerable = true # Grant temporary invulnerability
	visible = true # Ensure player is visible
	set_physics_process(true) # Ensure player processing is re-enabled
	
	# Visual feedback for revival (e.g., flash, glow)
	modulate = Color(0.5, 1, 0.5, 1) # Greenish tint
	await get_tree().create_timer(0.1).timeout # Short flash
	modulate = Color(1, 1, 1, 1)

	# Invulnerability duration
	%InvulnerabilityTimer.start(3.0) 
	
	revived.emit() # Signal that the player was revived
	print("Player revived!")


func _on_VibrationCooldownTimer_timeout():
	can_vibrate = true

func _on_InvulnerabilityTimer_timeout():
	is_invulnerable = false
	print("Player no longer invulnerable.")
