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
var player_attack_speed :float = 1.35
var bullet_scale := 1.0
var crit_chance := 0.0


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
