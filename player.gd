extends CharacterBody2D

# Your existing signals + new ones
signal health_depleted
signal revived
signal player_hit # Emitted when player takes damage
signal gem_collected(amount: int) # Emitted when player collects a gem

# Your existing variables (e.g., speed, health, max_health, etc.)
# Base values that will be modified by Autoload percentages
var base_speed: float = 150.0
var base_max_health: float = 100.0

var speed: float = base_speed
var health: float = base_max_health
var max_health: float = base_max_health

# Add a variable to track if the player is currently hurt
var is_hurt: bool = false
var hurt_animation_duration: float = 0.3 # How long the hurt animation plays (adjust as needed)
var hurt_timer: float = 0.0

# Add a variable to track the last non-zero direction for idle animations
# Initialize to down or your preferred idle default, but ensure it's a normalized vector
var last_facing_direction: Vector2 = Vector2.DOWN # Renamed for clarity


# MOBILE MOVEMENT SUPPORT
var touch_start_pos := Vector2.ZERO
var touch_current_pos := Vector2.ZERO
var touching := false
var can_vibrate := true # Android vibration control
var is_invulnerable := false # For temporary invulnerability after revival

@onready var sprite: AnimatedSprite2D = %PixelBall # Your player sprite
@onready var health_progress_bar = %ProgressBar # Your player health bar (assuming direct child of Player)
@onready var hurt_box = %HurtBox # Assuming you have an Area2D named HurtBox for collision damage
@onready var vibration_cooldown_timer: Timer = %VibrationCooldownTimer # Timer for vibration cooldown
@onready var invulnerability_timer: Timer = %InvulnerabilityTimer # Timer for invulnerability after revive


func _ready():
	# It's important to set initial stats before setting health to max_health
	_update_stats()
	health = max_health # Ensure health starts at max after stats are updated
	health_progress_bar.max_value = max_health
	health_progress_bar.value = health

	# Connect timers
	vibration_cooldown_timer.timeout.connect(_on_VibrationCooldownTimer_timeout)
	invulnerability_timer.timeout.connect(_on_InvulnerabilityTimer_timeout)


# MOBILE MOVEMENT INPUT
func _unhandled_input(event: InputEvent) -> void:
	var screen_width = get_viewport_rect().size.x
	var move_side_left = not Autoload.controls_flipped

	if event is InputEventScreenTouch:
		var is_left_half_screen_touch = event.position.x < screen_width * 0.5

		if move_side_left != is_left_half_screen_touch:
			return # Touch is not on the designated movement side

		if event.pressed:
			touch_start_pos = event.position
			touch_current_pos = event.position
			touching = true
		else:
			touching = false

	elif event is InputEventScreenDrag:
		var is_left_half_screen_drag = event.position.x < screen_width * 0.5
		if move_side_left != is_left_half_screen_drag:
			return # Drag is not on the designated movement side
		touch_current_pos = event.position


func _physics_process(delta: float) -> void:
	# MOVEMENT LOGIC (COMBINED MOBILE AND KEYBOARD)
	var input_direction = Vector2.ZERO # Renamed from 'direction' to avoid confusion

	# Mobile input
	if touching:
		input_direction += (touch_current_pos - touch_start_pos).normalized()

	# Keyboard input
	input_direction += Input.get_vector("move_left", "move_right", "move_up", "move_down")

	# Normalize to prevent faster diagonal movement
	if input_direction.length() > 1.0:
		input_direction = input_direction.normalized()

	# Apply friction/deceleration if no input
	if input_direction.length() == 0:
		velocity = velocity.move_toward(Vector2.ZERO, speed * 5 * delta) # Adjust 5 for deceleration speed
	else:
		velocity = input_direction * speed # Apply speed

	# ANIMATION UPDATE
	# Update last_facing_direction only when moving significantly
	if input_direction.length() > 0.1: # Use a small threshold to avoid tiny jitters changing direction
		last_facing_direction = input_direction.normalized() # Store the normalized direction

	# Handle hurt state
	if is_hurt:
		hurt_timer -= delta
		if hurt_timer <= 0:
			is_hurt = false
			# No need to call _update_animation here, it's called after this block
			# and the `is_hurt` flag will be false, allowing normal animations to resume.

	# Always call to ensure animation is updated based on current state
	_update_animation(input_direction) 

	# REMOVED: Horizontal flipping based on velocity.x
	# If your animations (e.g., run-left, run-right) are distinct and already
	# facing the correct direction in their sprite frames, you DO NOT need this.
	# If your "left" animations are literally just flipped "right" ones,
	# then you should simplify your animation names (e.g., only have 'run-right')
	# and re-enable a more sophisticated flip_h logic.
	# Assuming distinct animations:
	# if velocity.x < 0:
	#    sprite.flip_h = true
	# elif velocity.x > 0:
	#    sprite.flip_h = false

	move_and_slide() # Perform movement


	# PLAYER TAKES DAMAGE FROM OVERLAPPING MOBS
	if not is_invulnerable: # Only take damage if not invulnerable
		var overlapping_mobs = hurt_box.get_overlapping_bodies() # Use the @onready var
		if overlapping_mobs.size() > 0:
			var total_contact_damage = Autoload.base_contact_damage_per_second * overlapping_mobs.size()

			# Apply armor percentage reduction here, using Autoload.player_armor_percent
			var final_damage = total_contact_damage * (1.0 - Autoload.player_armor_percent)

			health -= final_damage * delta # Damage over time from collision

			emit_signal("player_hit") # Emit for screen shake/sfx

			# VIBRATION
			if Autoload.vibration_enabled and can_vibrate:
				Input.vibrate_handheld(
					Autoload.vibration_duration_ms,
					Autoload.vibration_amplitude
				)
				can_vibrate = false
				vibration_cooldown_timer.start(Autoload.vibration_cooldown_sec)

			# VFX
			self.modulate = Color(1, 0.3, 0.3) # Flash red
			# Using call_deferred with await for better timing on visual effects
			await get_tree().create_timer(0.05).timeout
			self.modulate = Color(1, 1, 1, 1) # Reset

			health_progress_bar.value = health

			if health <= 0.0:
				health = 0 # Ensure health doesn't go negative on display
				health_depleted.emit()
				set_physics_process(false) # Stop player movement/damage
				visible = false # Hide player
				print("Player health depleted! Signalling Game Over.")

	# HEALTH REGENERATION
	if Autoload.health_regen > 0.0:
		health += Autoload.health_regen * delta
		health = min(health, max_health) # Ensure health doesn't go above max_health

	# Update the progress bar after potential health regeneration
	health_progress_bar.value = health


func _update_animation(current_input_direction: Vector2):
	var anim_prefix = ""
	var current_anim_suffix = ""

	# Determine the direction for animation: prefer current input, else use last facing
	# Check if there's significant horizontal input for side animations,
	# then vertical, then fallback to last_facing_direction.
	if current_input_direction.x < -0.1: # Moving left (keyboard or joystick)
		current_anim_suffix = "-left"
		sprite.flip_h = false # Assume 'left' animation is already correctly oriented
	elif current_input_direction.x > 0.1: # Moving right (keyboard or joystick)
		current_anim_suffix = "-right"
		sprite.flip_h = false # Assume 'right' animation is already correctly oriented
	elif current_input_direction.y < -0.1: # Moving up
		current_anim_suffix = "-up"
		sprite.flip_h = false # Reset flip if changing to vertical
	elif current_input_direction.y > 0.1: # Moving down
		current_anim_suffix = "-down"
		sprite.flip_h = false # Reset flip if changing to vertical
	else: # No significant movement, use last_facing_direction for idle or hurt state
		# Use last_facing_direction to determine idle/hurt direction
		if last_facing_direction.x < -0.1:
			current_anim_suffix = "-left"
			sprite.flip_h = false
		elif last_facing_direction.x > 0.1:
			current_anim_suffix = "-right"
			sprite.flip_h = false
		elif last_facing_direction.y < -0.1:
			current_anim_suffix = "-up"
			sprite.flip_h = false
		else: # Default to down if no clear last direction (e.g., first frame)
			current_anim_suffix = "-down"
			sprite.flip_h = false # Ensure no horizontal flip for vertical animations

	if is_hurt:
		anim_prefix = "hurt"
	elif current_input_direction.length() > 0.1: # Player is moving significantly
		anim_prefix = "run"
	else: # Player is idle (no significant movement)
		anim_prefix = "idle"

	var animation_to_play = anim_prefix + current_anim_suffix
	
	# Only change animation if it's different to avoid re-playing and resetting
	if sprite.animation != animation_to_play:
		if sprite: # Check if animation exists
			sprite.play(animation_to_play)
		else:
			# Fallback for missing animations (e.g., if you don't have all directional hurt anims)
			printerr("Animation '", animation_to_play, "' not found. Falling back to 'idle-down'.")
			sprite.play("idle-down") # Or a generic "idle" / "run"

# Player damage function for external calls (e.g., projectiles)
func take_damage(amount: float):
	if is_invulnerable:
		return # Do nothing if invulnerable

	# Apply armor percentage reduction here
	var final_damage = amount * (1.0 - Autoload.player_armor_percent)

	health -= final_damage
	health_progress_bar.value = health

	emit_signal("player_hit") # Emit for screen shake/sfx

	# Trigger hurt animation
	is_hurt = true
	hurt_timer = hurt_animation_duration # Reset timer for hurt animation duration
	
	# When playing hurt animation, use the last_facing_direction as the basis
	_update_animation(Vector2.ZERO) # Pass zero to force idle/hurt logic based on last_facing_direction

	# VFX (Flash red)
	self.modulate = Color(1, 0.3, 0.3)
	await get_tree().create_timer(0.05).timeout # Small delay
	self.modulate = Color(1, 1, 1, 1) # Reset

	if health <= 0:
		health = 0
		emit_signal("health_depleted")

# Call this from your Gem scene when it detects collision with the player
func collect_gem(amount: int):
	emit_signal("gem_collected", amount)

# Function to handle actual revival (called by Gameplay button)
func revive_player():
	health = max_health * 0.5 # Revive with half health, based on current max_health
	position = Vector2(300, 300) # Teleport to a safe spot, or wherever your spawn point is
	health_progress_bar.value = health
	visible = true # Make player visible
	set_physics_process(true) # Resume player movement
	is_invulnerable = true
	
	# Visual feedback for revival (e.g., flash, glow)
	modulate = Color(0.5, 1, 0.5, 1) # Greenish tint
	await get_tree().create_timer(0.1).timeout # Short flash
	modulate = Color(1, 1, 1, 1)

	# Invulnerability duration
	invulnerability_timer.start(3.0)
	
	emit_signal("revived") # Signal that the player was revived
	print("Player revived!")


func _update_stats():
	# Implement your stat updates here based on Autoload
	speed = base_speed * Autoload.player_speed_percent
	max_health = base_max_health * Autoload.player_health_percent

	if health_progress_bar:
		health_progress_bar.max_value = max_health
	health = min(health, max_health)
	health_progress_bar.value = health
	print("Player stats updated: Speed=", speed, ", Max Health=", max_health)

# Invulnerability timer timeout
func _on_InvulnerabilityTimer_timeout():
	is_invulnerable = false
	print("Player no longer invulnerable.")

# Vibration cooldown timer timeout
func _on_VibrationCooldownTimer_timeout():
	can_vibrate = true
