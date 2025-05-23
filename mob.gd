extends CharacterBody2D

signal gem

var health = 100

@onready var player = get_node("/root/MainMap/player")

@export var coin: PackedScene = preload("res://coin.tscn")
@export var coin_big: PackedScene = preload("res://coin_big.tscn")

func _ready() -> void:
	pass #play walk animation


func _physics_process(delta: float) -> void:
	var level = Autoload.level
	var enemy_speed = Autoload.enemy_speed
	var direction = global_position.direction_to(player.global_position)
	velocity= direction * 600.0 * enemy_speed
	move_and_slide()


func take_damage():
	health -= 50 * Autoload.player_damage_percent
	#play hurt animation
	
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
	


func _on_gem() -> void:
	var gem = preload("res://gem.tscn").instantiate()
	get_parent().add_child(gem)
	gem.global_position = global_position
