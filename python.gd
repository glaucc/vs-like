extends CharacterBody2D

signal gem

var health: float
var max_health: float # Set in reset based on mob type

@onready var player = get_node("/root/MainMap/player")

@export var coin: PackedScene = preload("res://coin.tscn")
@export var coin_big: PackedScene = preload("res://coin_big.tscn")

var _pool_group_name: String # This will store "mob", "bat", "python", etc.

# No _ready() needed here if stats are initialized in reset()

func _physics_process(delta: float) -> void:
	var level = Autoload.level # Consider if level is used for mob difficulty here
	var enemy_speed_modifier = Autoload.enemy_speed # Renamed for clarity to avoid conflict with potential mob_base_speed
	var direction = global_position.direction_to(player.global_position)
	
	# You'll likely want a base_speed for each mob type, then apply the modifier
	# Example: var base_mob_speed = 60.0 # Or get from data
	# velocity = direction * base_mob_speed * enemy_speed_modifier
	
	# For now, using your existing 600.0 directly as base
	velocity = direction * 600.0 * enemy_speed_modifier
	move_and_slide()


func take_damage(damage: float, is_crit: bool = false):
	
	# Apply damage
	health -= damage
	
	# Show floating damage number
	show_damage_number(damage, is_crit)
	
	# Enemy Death
	if health <= 0:
		reset_physics_interpolation()
		
		# NOTE: You had two lines returning to pool. Only one is needed.
		# PoolManager.return_to_pool(_pool_group_name, self) # This is the correct one to use
		# PoolManager.return_to_pool("mob", self) # This line is redundant and potentially wrong if _pool_group_name is not "mob"

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
			var new_coin_big = coin_big.instantiate() # Renamed to avoid shadowing PackedScene variable
			get_parent().add_child(new_coin_big)
			new_coin_big.global_position = global_position
			new_coin_big.global_position.x += 50
		elif rng < effective_regular_coin_chance:
			var new_coin = coin.instantiate() # Renamed to avoid shadowing PackedScene variable
			get_parent().add_child(new_coin)
			new_coin.global_position = global_position
			new_coin.global_position.x += 30
			
		PoolManager.return_to_pool(_pool_group_name, self) # Use the stored group name
		set_process(false)
		visible = false
			
	else:
		#play hurt animation
		self.modulate = Color(1, 1, 1) # Flash red
		await get_tree().create_timer(0.05).timeout
		self.modulate = Color(1, 1, 1, 1) # Reset
		
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
	var gem = preload("res://gem.tscn").instantiate()
	get_parent().add_child(gem)
	gem.global_position = global_position


# NEW: The reset function for pooled mobs
func reset(pool_group_name_arg: String):
	_pool_group_name = pool_group_name_arg # Store the group name

	# --- Mob health initialization ---
	# This is where you'd make mob health different based on _pool_group_name
	match _pool_group_name:
		"mob":
			max_health = 40
		"bat":
			max_health = 60 # Example health for bat
		"python":
			max_health = 80 # Example health for python
		"psycho":
			max_health = 120 # Example health for psycho
		"bull_boss":
			max_health = 500 # Example health for boss
		"giant_boss":
			max_health = 800
		"boss1": # Assuming this is your final boss from preload
			max_health = 1200
		_: # Default if group name not found (shouldn't happen if setup correctly)
			max_health = 40
	
	health = max_health # Reset health to max
	
	# Reset any internal state like animation or timers
	visible = true
	set_process(true)
	self.modulate = Color(1,1,1,1) # Ensure color is reset
