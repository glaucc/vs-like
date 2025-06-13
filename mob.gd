extends CharacterBody2D

signal gem

var health: float
var max_health: float # Set in reset based on mob type

@onready var player = get_node("/root/MainMap/player")
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D # <--- Corrected: Using $ for direct child

@export var coin: PackedScene = preload("res://coin.tscn")
@export var coin_big: PackedScene = preload("res://coin_big.tscn")

var _pool_group_name: String # This will store "mob", "bat", "python", etc.

# We'll still track last facing direction to maintain visual orientation when not moving
var last_facing_direction: Vector2 = Vector2.DOWN # Initialize to down


func _physics_process(delta: float) -> void:
	var level = Autoload.level # Consider if level is used for mob difficulty here
	var enemy_speed_modifier = Autoload.enemy_speed # Renamed for clarity to avoid conflict with potential mob_base_speed
	var direction = global_position.direction_to(player.global_position)
	
	velocity = direction * 600.0 * enemy_speed_modifier
	move_and_slide()

	# Call the animation update function here
	_update_animation(direction)


func take_damage(damage: float, is_crit: bool = false):
	
	# Apply damage
	health -= damage
	
	# Show floating damage number
	show_damage_number(damage, is_crit)
	
	# Enemy Death
	if health <= 0:
		reset_physics_interpolation()
		
		
		#$CollisionShape2D.hide()
		$".".hide()
		
		gem.emit() # For XP drop
		
		const SMOKE_EXPLOSION = preload("res://smoke_explosion/smoke_explosion.tscn")
		var smoke = SMOKE_EXPLOSION.instantiate()
		get_parent().add_child(smoke)
		smoke.global_position = global_position
		
		var rng = randf()
		
		# Apply player luck to coin drops
		var effective_big_coin_chance = 0.02 * Autoload.player_luck_percent
		var effective_regular_coin_chance = 0.2 * Autoload.player_luck_percent

		if rng < effective_big_coin_chance:
			var new_coin_big = coin_big.instantiate()
			get_parent().add_child(new_coin_big)
			new_coin_big.global_position = global_position
			new_coin_big.global_position.x += 50
		elif rng < effective_regular_coin_chance:
			var new_coin = coin.instantiate()
			get_parent().add_child(new_coin)
			new_coin.global_position = global_position
			new_coin.global_position.x += 30
			
		PoolManager.return_to_pool(_pool_group_name, self) # Use the stored group name
		set_process(false)
		visible = false
			
	else:
		# Flash red when hurt, but no special "hurt" animation for mobs based on your clarification
		self.modulate = Color(1, 0.3, 0.3) 
		await get_tree().create_timer(0.05).timeout
		self.modulate = Color(1, 1, 1, 1) # Reset color
		
		# Knockback
		var knockback = global_position.direction_to(player.global_position) * -100
		global_position += knockback


func show_damage_number(damage: float, is_crit: bool = false) -> void:
	var label_scene = preload("res://damage_label.tscn")
	var label = label_scene.instantiate()
	label.text = str(round(damage))

	# Set color based on damage
	if is_crit:
		label.modulate = Color(1, 0, 1) # Purple for critical hit
	elif damage < 20:
		label.modulate = Color(1, 1, 1) # White
	elif damage < 50:
		label.modulate = Color(1, 0.8, 0) # Yellow
	elif damage < 150:
		label.modulate = Color(1, 0.4, 0) # Orange
	else:
		label.modulate = Color(1, 0, 0) # Red

	get_parent().add_child(label)
	label.global_position = global_position
	label.global_position.y -= 40


func _on_gem() -> void:
	var gem_instance = preload("res://gem.tscn").instantiate()
	get_parent().add_child(gem_instance)
	gem_instance.global_position = global_position


# NEW: The reset function for pooled mobs
func reset(pool_group_name_arg: String):
	_pool_group_name = pool_group_name_arg # Store the group name

	# --- Mob health initialization ---
	match _pool_group_name:
		"mob":
			max_health = 40
		"bat":
			max_health = 60
		"python":
			max_health = 80
		"psycho":
			max_health = 120
		"man_eating_flower":
			max_health = 250
		"pumpking":
			max_health = 590
		"ghost":
			max_health = 400
		"small_worm":
			max_health = 210
		"big_worm":
			max_health = 670
		"slime":
			max_health = 900
		"bull_boss":
			max_health = 500
		"giant_boss":
			max_health = 800
		"boss1":
			max_health = 1200
		_:
			max_health = 40
			
	health = max_health # Reset health to max
	
	# Reset any internal state like animation or timers
	visible = true
	set_process(true)
	self.modulate = Color(1,1,1,1) # Ensure color is reset
	$".".show()
	#$CollisionShape2D.show()
	
	# When resetting, play a default animation and reset flip
	if animated_sprite:
		animated_sprite.play("run-down") # Or a single frame 'default' animation if you have one
		animated_sprite.stop() # Stop the animation to show the first frame
		animated_sprite.flip_h = false


# --- REVISED: Animation Update Function for Enemies ---
func _update_animation(current_move_direction: Vector2):
	if not animated_sprite: # Safety check
		return

	var anim_to_play = ""
	animated_sprite.flip_h = false # Reset flip state each frame

	# Determine direction based on movement
	if current_move_direction.length() > 0.1: # If moving significantly
		# Prioritize horizontal movement for side animations, then vertical
		if abs(current_move_direction.x) > abs(current_move_direction.y):
			if current_move_direction.x < 0: # Moving left
				anim_to_play = "run-left"
				last_facing_direction = Vector2.LEFT # Update last facing
			else: # Moving right
				anim_to_play = "run-left" # Use 'run-left' animation
				animated_sprite.flip_h = true # Flip horizontally for right
				last_facing_direction = Vector2.RIGHT # Update last facing
		else: # More vertical movement or equal, prioritize vertical
			if current_move_direction.y < 0: # Moving up
				anim_to_play = "run-up"
				last_facing_direction = Vector2.UP # Update last facing
			else: # Moving down
				anim_to_play = "run-down"
				last_facing_direction = Vector2.DOWN # Update last facing

		if animated_sprite.animation != anim_to_play:
			if animated_sprite:
				animated_sprite.play(anim_to_play)
			else:
				printerr("Animation '", anim_to_play, "' not found for enemy. Playing last known animation.")
				# If a specific animation isn't found, just keep the current one or stop
				# animated_sprite.stop() # Option: stop if animation not found
	else: # Not moving significantly
		# If not moving, ensure animation is stopped on the last played frame
		if animated_sprite.is_playing():
			animated_sprite.stop()
		
		# Optionally, you can set the frame to a specific "idle" frame if you have a default
		# or just leave it on the last frame of the run animation.
		# If you have single-frame "idle-down", "idle-left", "idle-up" frames but not as full animations,
		# you could manually set animated_sprite.animation = "idle-down" and animated_sprite.frame = X
		# For now, it will just stop on the last run frame.
