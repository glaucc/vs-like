# bullet_laser.gd
extends Area2D

@onready var animated_sprite: AnimatedSprite2D = %AnimatedSprite2D # Make sure your AnimatedSprite2D is named this
@onready var collision_shape: CollisionShape2D = %CollisionShape2D # Make sure your CollisionShape2D is named this

# These will be set by the LaserWeapon when the laser is created
var laser_damage_per_second: float = 0.0
var laser_duration: float = 0.0
var current_lifetime_timer: float = 0.0

# Using a Dictionary to store cooldowns per enemy for continuous damage
# This prevents applying damage every single physics frame to the same enemy
var enemy_damage_cooldowns: Dictionary = {}
var damage_tick_interval: float = 0.1 # Damage applied every 0.1 seconds to an enemy

func _ready():
	# Play the laser animation (e.g., "active" or "default")
	animated_sprite.play("default") # Assuming you have a default animation for the laser
	
	# The laser's collision shape might be disabled by default in the scene
	# We will enable it when setup_laser is called.
	collision_shape.set_deferred("disabled", true) # Start disabled, enabled by setup_laser

func setup_laser(damage_per_sec: float, duration: float, rotation_degrees: float):
	laser_damage_per_second = damage_per_sec #
	laser_duration = duration #
	current_lifetime_timer = duration # Initialize the timer for its lifetime

	self.rotation_degrees = rotation_degrees # Set the visual and collision rotation
	
	# Enable the collision shape now that its properties are set
	collision_shape.set_deferred("disabled", false) # Enable collision for detection
	
	# We will primarily use _physics_process for continuous damage,
	# so we don't connect body_entered/exited directly here for main damage logic.
	# We want to check all overlaps continuously.

	print("DEBUG: Laser (bullet_laser.tscn) setup. Damage/s:", laser_damage_per_second, " Duration:", laser_duration, " Rotation:", rotation_degrees) #

func _physics_process(delta: float):
	if current_lifetime_timer > 0:
		current_lifetime_timer -= delta
		
		# Get all bodies currently overlapping with the laser's Area2D
		var overlapping_bodies = get_overlapping_bodies() #

		# Process damage for each enemy in range
		for body in overlapping_bodies: #
			if body.is_in_group("enemies") and body.has_method("take_damage"): #
				# Check cooldown for this specific enemy
				if not enemy_damage_cooldowns.has(body) or enemy_damage_cooldowns[body] <= 0: #
					var damage_this_tick = laser_damage_per_second * damage_tick_interval #
					body.take_damage(damage_this_tick) #
					print("DEBUG: Laser hit: ", body.name, " for ", damage_this_tick, " damage. (Total damage/s: ", laser_damage_per_second, ")")
					
					# Reset cooldown for this enemy
					enemy_damage_cooldowns[body] = damage_tick_interval #
			# Optional: If you want the laser to disappear if it hits a wall/environment
			# if body.is_in_group("walls"): # Add your walls to a group
			#     queue_free()
			#     return # Stop processing if it hits a wall
		
		# Decrement cooldowns for all tracked enemies
		for enemy in enemy_damage_cooldowns.keys(): #
			enemy_damage_cooldowns[enemy] -= delta #

		# Optional: Animate the laser fading out
		animated_sprite.modulate.a = current_lifetime_timer / laser_duration #

		if current_lifetime_timer <= 0:
			queue_free() # Laser's lifetime is over, remove it
			print("DEBUG: Laser lifetime ended. Queueing free.")
	else:
		# If the timer somehow went below zero without queuing free
		queue_free() #

# Note: The _on_body_entered function is removed because we are using
# get_overlapping_bodies() in _physics_process for continuous damage.
# If you only wanted a one-time hit on entry, you could use _on_body_entered
# but that's not typical for a piercing laser beam.
