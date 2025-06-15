# Explosion.gd (attached to explosion_rocket.tscn)
extends Area2D

@onready var animated_sprite: AnimatedSprite2D = %AnimatedSprite2D # Adjust name if different
@onready var explosion_sound: AudioStreamPlayer = %ExplosionSound # Make sure ExplosionSound node exists

var explosion_damage: int = 0
var explosion_radius: float = 0.0

func _ready() -> void:
	# Ensure monitoring is on for body_entered (default for Area2D)
	set_deferred("monitoring", true)
	
	# Connect animation finished signal to queue_free
	animated_sprite.animation_finished.connect(_on_AnimatedSprite2D_animation_finished)

	# Play the explosion sound as soon as it's ready
	if explosion_sound:
		explosion_sound.play()

	# Damage is applied after setup_explosion is called, usually immediately after instantiation
	# No need to call apply_aoe_damage here; it's called by setup_explosion or after it.

func setup_explosion(damage: int, radius: float) -> void:
	explosion_damage = damage # The base damage from the RocketLauncher
	explosion_radius = radius # The radius for the AOE damage

	# Scale the CollisionShape2D to match the explosion_radius
	var collision_shape = $CollisionShape2D # Adjust path if different if not a direct child
	print(collision_shape)
	if collision_shape and collision_shape.shape is CircleShape2D:
		(collision_shape.shape as CircleShape2D).radius = explosion_radius
		# Make sure the collision shape is enabled for the brief moment of damage
		collision_shape.set_deferred("disabled", false)
	else:
		printerr("Explosion.gd: CollisionShape2D not found or not a CircleShape2D!")
	
	# ✅ Wait one frame for physics update
	await get_tree().physics_frame
	apply_aoe_damage()


func apply_aoe_damage() -> void:
	# Get all overlapping bodies that the explosion detects
	await get_tree().physics_frame
	var bodies_in_range = get_overlapping_bodies()
	
	
	for body in bodies_in_range:
		print(body, body is PhysicsBody2D)
		# Check if the body is an enemy and can take damage
		if body.is_in_group("enemies") and body.has_method("take_damage"):
			# Calculate final damage, including player damage percent and crit chance
			var final_damage = explosion_damage * Autoload.player_damage_percent
			var is_crit = randf() < Autoload.crit_chance
			if is_crit:
				final_damage *= Autoload.crit_multiplier
			
			body.take_damage(final_damage, is_crit)
			print("Explosion dealt ", final_damage, " damage to ", body.name, ". Crit: ", is_crit)
		# You might also want to damage the player if they are in the explosion radius,
		# but be careful with friendly fire.
		# elif body.is_in_group("player") and body.has_method("take_damage"):
		#     body.take_damage(some_player_damage_value)
			
	# Disable the collision shape after damage is applied to prevent multiple hits
	# This is important if your explosion animation is longer than a single frame
	if $CollisionShape2D:
		$CollisionShape2D.set_deferred("disabled", true)


func _on_AnimatedSprite2D_animation_finished() -> void:
	# Use pool_manager to free if available, otherwise queue_free
	if Autoload.has_method("pool_manager") and Autoload.pool_manager.has_method("free_instance"):
		Autoload.pool_manager.free_instance("explosion_effect", self) # Assuming "explosion_effect" is your pool name
	else:
		queue_free()
