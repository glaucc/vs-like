extends Node2D

var level:int = Autoload.level
var required_xp = [0,50,100,150,300,650,790,850,950,1000,50000]

@export var coin_scene: PackedScene
@export var big_coin_scene: PackedScene
@export var drop_chance: float = 0.5 #50% percent drop chance
@export var big_coin_chance: float = 0.07
@export var max_coins: int = 3 # Max normal coins if big not dropped


func _physics_process(delta: float) -> void:
	Autoload.level = level
	var score = Autoload.score
	%LevelProgressBar.value = score - required_xp[level - 1]
	%LevelProgressBar.max_value = required_xp[level] - required_xp[level - 1]
	%Score.text = "Level " + str(level) + " " + str(score) + "/" + str(required_xp[level])
	if score >= required_xp[level]:
		#open level up pop up
		%UpgradeMenu.show()
		get_tree().paused = true
		level += 1
	if level == 2:
		%MobSpawnTimer.wait_time = 0.8
	elif level == 3:
		%MobSpawnTimer.wait_time = 0.4
		%gun2.set_process_mode(Node.PROCESS_MODE_INHERIT)
		%gun2.show()
	elif level == 4:
		%MobSpawnTimer.wait_time = 0.25
		%gun3.set_process_mode(Node.PROCESS_MODE_INHERIT)
		%gun3.show()
	elif level == 5:
		%MobSpawnTimer.wait_time = 0.17
		%gun4.set_process_mode(Node.PROCESS_MODE_INHERIT)
		%gun4.show()
	elif level == 6:
		%MobSpawnTimer.wait_time = 0.14
		%gun5.set_process_mode(Node.PROCESS_MODE_INHERIT)
		%gun5.show()
	elif level == 7:
		%MobSpawnTimer.wait_time = 0.13
		%gun6.set_process_mode(Node.PROCESS_MODE_INHERIT)
		%gun6.show()
		

func spawn_mob():
	var new_mob = preload("res://mob.tscn").instantiate()
	%PathFollow2D.progress_ratio = randf()
	new_mob.global_position = %PathFollow2D.global_position
	add_child(new_mob)


func _on_mob_spawn_timer_timeout() -> void:
	spawn_mob()


func _on_player_health_depleted() -> void:
	%GameOver.show()
	get_tree().paused = true



func _on_button_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
	Autoload.reset_variables()
	level = 1


func _on_upgrade_button_1_pressed() -> void:
	get_tree().paused = false
	%UpgradeMenu.hide()


func _on_upgrade_button_2_pressed() -> void:
	get_tree().paused = false
	%UpgradeMenu.hide()


func _on_upgrade_button_3_pressed() -> void:
	get_tree().paused = false # Replace with function body.
	%UpgradeMenu.hide()


func _on_upgrade_button_4_pressed() -> void:
	get_tree().paused = false # Replace with function body.
	%UpgradeMenu.hide()
