extends Node

var player_coins:int = 0
var save_path: String = "user://save_data.dat"

var score: int = 0
var enemy_speed:float = 0.1
var level:int = 1
var bullet_speed:int = 500
var bullet_range:int = 500
var player_speed_percent:float = 1.0
var player_damage_percent:float = 1.0
var player_health_percent:float = 1.0
var player_curse_percent:float = 1.0
var player_luck_percent:float = 1.0
var player_armor_percent:float = 1.0
var player_attack_speed :float = 4
var bullet_scale := 1.0

var crit_chance := 0.0
var crit_multiplier:float = 3.0

var gun1_bullets:int = 1
var gun2_bullets:int = 1
var gun3_bullets:int = 1
var gun4_bullets:int = 1
var gun5_bullets:int = 1
var gun6_bullets:int = 1
var health_regen:float = 0.0

var gun_base_damage:float = 8.0


# Shotgun
var shotgun_base_damage:int = 20

var shotgun_magazine:int = 6
var shotgun_spread_bullets:int = 5
var shotgun_cooldown:float = 0.3
var shotgun_reload_duration:float = 2.0

var shotgun_bullet_speed:int = 700
var shotgun_bullet_range:int = 500


func _ready() -> void:
	load_coins()

func reset_variables():
	level = 1
	bullet_speed = 500
	score = 0

func save_coins():
	var save_file = FileAccess.open(save_path, FileAccess.WRITE)
	if save_file:
		save_file.store_var(player_coins)
		save_file.close()
	
func load_coins():
	var save_file = FileAccess.open(save_path, FileAccess.READ)
	if save_file:
		player_coins = save_file.get_var(player_coins)
		save_file.close()
		print(player_coins)

func add_coins(amount: int) -> void:
	player_coins += amount
	save_coins()
