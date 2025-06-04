extends CharacterBody2D

signal gem

var health = 1800
var knockback:int = -10

@onready var player = get_node("/root/MainMap/player")

@export var coin: PackedScene = preload("res://coin.tscn")
@export var coin_big: PackedScene = preload("res://coin_big.tscn")

#func _ready() -> void:
	#pass
	#


func _physics_process(delta: float) -> void:
	var level = Autoload.level
	var enemy_speed = Autoload.enemy_speed
	var direction = global_position.direction_to(player.global_position)
	velocity= direction * 600.0 * enemy_speed
	move_and_slide()


func take_damage(damage: float, is_crit: bool = false):
	
	# Apply damage
	health -= damage
	
	# Show floating damage number
	show_damage_number(damage, is_crit)
	
	# Enemy Death
	if health <= 0:
		queue_free()
		gem.emit()
		#Autoload.add_coins(1)
		#print(Autoload.player_coins)
		
		const SMOKE_EXPLOSION = preload("res://smoke_explosion/smoke_explosion.tscn")
		var smoke = SMOKE_EXPLOSION.instantiate()
		get_parent().add_child(smoke)
		smoke.global_position = global_position
		
		var rng = randf()
		
		if rng < 0.02:
			# 0.2% chance to drop big coin
			var coin_big = coin_big.instantiate()
			get_parent().add_child(coin_big)
			coin_big.global_position = global_position
			coin_big.global_position.x += 50
		elif rng < 0.2:
			# 0.2% chance to drop regular coin
			var coin = coin.instantiate()
			get_parent().add_child(coin)
			coin.global_position = global_position
			coin.global_position.x += 30
		# else: no drop (50%)
	else:
		#play hurt animation
		self.modulate = Color(1, 0.3, 0.3) # Flash red
		await get_tree().create_timer(0.05).timeout
		self.modulate = Color(1, 1, 1, 1) # Reset
		
		# Knockback
		var knockback = global_position.direction_to(player.global_position) * knockback
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
