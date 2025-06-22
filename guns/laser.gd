extends Area2D

@onready var shooting_point: Marker2D = %ShootingPoint
@onready var cooldown_timer: Timer = %CooldownTimer # To control fire rate
@onready var shoot_sound: AudioStreamPlayer = %ShootSound
@onready var camera = %Camera2D # Adjust path!

var bullet_laser_scene: PackedScene = preload("res://bullets/bullet_laser.tscn") # Make sure this path is correct!

# Stats from Autoload (adjust these names to match your Autoload if different)
var laser_damage_per_second: float = Autoload.laser_damage_per_second # This will be the base damage passed to the laser
var laser_duration: float = Autoload.laser_duration # How long each laser beam stays active
var cooldown: float = Autoload.laser_cooldown # How often the laser fires
var recoil_strength_visual: float = 15.0 # Visual recoil for the gun itself
var recoil_return_speed: float = 30.0 # Snappy return for laser gun visuals

# Recoil variables for the gun's sprite
var recoil_offset: Vector2 = Vector2.ZERO # Current visual offset due to recoil

var can_shoot := true # Keep this for logic, but timer will drive auto-fire

func _ready() -> void:
	# Set up initial cooldown
	cooldown_timer.wait_time = cooldown
	cooldown_timer.timeout.connect(_on_CooldownTimer_timeout)
	cooldown_timer.start() # Start the timer immediately to fire the first shot


func _physics_process(delta):
	# Handle recoil return for the gun's visual
	if recoil_offset.length() > 0.1:
		recoil_offset = recoil_offset.move_toward(Vector2.ZERO, recoil_return_speed * delta)
	else:
		recoil_offset = Vector2.ZERO
	
	# Apply the recoil offset to the weapon's local position
	position = recoil_offset

	# Targeting logic
	var enemies = get_overlapping_bodies() # Requires this node to have an Area2D/CollisionShape2D
	var target_enemy: CharacterBody2D = null
	var min_distance: float = INF

	if not enemies.is_empty():
		for enemy in enemies:
			# Ensure the overlapping node is an enemy type you want to target
			if enemy is CharacterBody2D and enemy.is_in_group("enemies"): # Add group check for robustness
				var distance = global_position.distance_to(enemy.global_position)
				if distance < min_distance:
					min_distance = distance
					target_enemy = enemy # Store the closest enemy

	if target_enemy: # Only if an enemy was found within overlapping bodies
		look_at(target_enemy.global_position) # <-- Move look_at OUTSIDE the loop
		# The target_direction variable below is now correctly derived from the final target_enemy
		# target_direction = (target_enemy.global_position - global_position).normalized()
	else:
		# Optional: If no target, perhaps point in a default direction or last known direction
		# look_at(global_position + Vector2.RIGHT) # Example: point right
		pass # Or do nothing, weapon stays in last position

	# The actual shooting is now solely controlled by the CooldownTimer timeout
	# No need for 'if can_shoot:' check here within _physics_process for shooting.




func _on_CooldownTimer_timeout():
	# When the timer times out, we are allowed to shoot again.
	# We call shoot(), and shoot() will then restart the timer.
	
	# Get the direction the gun is currently facing (after look_at in _physics_process)
	# Using `transform.x` directly from the gun's transform will give its forward vector.
	var shoot_direction = global_transform.x.normalized()
	
	shoot(shoot_direction)
	# The timer automatically restarts because `autostart` is not used within the timeout.
	# We explicitly start it after a shot.
	cooldown_timer.start(cooldown) # Restart the cooldown timer for the next shot


func shoot(direction: Vector2):
	if not bullet_laser_scene:
		printerr("ERROR: bullet_laser.tscn not assigned in LaserWeapon.")
		return

	var laser_instance = bullet_laser_scene.instantiate()
	get_tree().current_scene.add_child(laser_instance)

	laser_instance.global_position = shooting_point.global_position
	laser_instance.rotation = direction.angle() # Set the rotation of the beam instance

	# Pass damage per second and duration to the laser
	laser_instance.setup_laser(laser_damage_per_second, laser_duration, rad_to_deg(laser_instance.rotation))

	camera.shake(0.05, 5.0) # Lighter screen shake for laser (adjust values)
	shoot_sound.play() # Play laser shoot sound
	
	_apply_recoil_visual() # Apply visual recoil to the gun itself


# --- Recoil Function for Gun Sprite ---
func _apply_recoil_visual():
	# Recoil directly opposite to the shooting_point's forward direction
	# This assumes shooting_point's X is forward
	var local_recoil_direction = -shooting_point.transform.x.normalized()
	recoil_offset = local_recoil_direction * recoil_strength_visual

# This would be called if your Autoload had upgrade stats affecting this weapon
func _update_stats():
	# Example: update based on Autoload multipliers if you have them
	laser_damage_per_second = Autoload.laser_damage_per_second # * Autoload.laser_damage_multiplier
	laser_duration = Autoload.laser_duration # * Autoload.laser_duration_multiplier
	cooldown = Autoload.laser_cooldown # / Autoload.laser_fire_rate_multiplier
	
	cooldown_timer.wait_time = cooldown # Update timer's wait time if cooldown changes
