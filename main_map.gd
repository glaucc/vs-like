extends Node2D

var time_passed: float = 0.0
var game_over:bool = false
var end_time:float = 0.0

var level:int = Autoload.level
var required_xp = [0,50,100,150,300,650,790,850,950,1000,50000]

var coins:int = 0

var current_selection:int = 0  # Track selected option
var max_selection = 3  # Assuming there are 4 upgrade options (adjust based on your UI)
var upgrade_options = ["Upgrade 1", "Upgrade 2", "Upgrade 3", "Upgrade 4"]

var easy_wave_spawned:bool = false
var medium_wave_spawned:bool = false
var hard_wave_spawned:bool = false
var boss1_spawned:bool = false
var boss2_spawned:bool = false
var boss3_spawned:bool = false

func handle_upgrade_input():
	if not %UpgradeMenu.visible:
		return

	var max_selection = 3
	if %Upgrade4.visible:
		max_selection = 4
	
	#Navigate
	if Input.is_action_just_pressed("move_up"):
		current_selection = max(current_selection - 1, 0)
	elif Input.is_action_just_pressed("move_down"):
		current_selection = min(current_selection + 1, max_selection - 1)
	
	# Select
	if Input.is_action_just_pressed("ui_accept"):
		match current_selection:
			0:
				%UpgradeButton1.emit_signal("pressed")
			1:
				%UpgradeButton2.emit_signal("pressed")
			2:
				%UpgradeButton3.emit_signal("pressed")
			3:
				if max_selection == 4:
					%UpgradeButton4.emit_signal("pressed")

	# Visual feedback (optional, highlight current selection)
	highlight_selection(max_selection)


func highlight_selection(count):
	var upgrades = [%Upgrade1, %Upgrade2, %Upgrade3, %Upgrade4]
	for i in range(count):
		upgrades[i].modulate = Color.YELLOW if i == current_selection else Color.WHITE


func _physics_process(delta: float) -> void:
	Autoload.level = level
	var score = Autoload.score
	%LevelProgressBar.value = score - required_xp[level - 1]
	%LevelProgressBar.max_value = required_xp[level] - required_xp[level - 1]
	%Score.text = "Level " + str(level) + " " + str(score) + "/" + str(required_xp[level])
	
	if score >= required_xp[level]:
		#open level up pop up - PAUSE MENU
		current_selection = 0
		var upgrade_count = 0
		if %Upgrade4.visible:
			upgrade_count == 4
		else:
			upgrade_count == 3
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
	
	if not get_tree().paused and not game_over:
		time_passed += delta
	
	var minutes = int(time_passed) / 60
	var seconds = int(time_passed) % 60
	%Time.text = "%02d:%02d" % [minutes, seconds]
	%Coins.text = str(coins)
	if time_passed > 0 and time_passed < 120:
		spawn_easy_wave()
	elif time_passed < 240 and time_passed > 120:
		spawn_medium_wave()
	elif time_passed < 300 and !boss1_spawned:
		spawn_boss1()
	elif time_passed < 480 and time_passed > 240:
		spawn_hard_wave()
	elif time_passed < 600 and !boss2_spawned:
		spawn_boss2()
	elif time_passed < 900 and !boss3_spawned:
		spawn_boss3()

func spawn_easy_wave():
	var new_mob = preload("res://mob.tscn").instantiate()
	easy_wave_spawned = true

func spawn_medium_wave():
	var new_mob = preload("res://python.tscn").instantiate()
	medium_wave_spawned = true

func spawn_hard_wave():
	var new_mob = preload("res://psycho.tscn").instantiate()
	hard_wave_spawned = true

func spawn_boss1():
	var new_mob = preload("res://boss_10.tscn").instantiate()
	boss1_spawned = true

func spawn_boss2():
	var new_mob = preload("res://bull-boss10.tscn").instantiate()
	boss2_spawned = true

func spawn_boss3():
	var new_mob = preload("res://giant-boss-20.tscn").instantiate()
	boss3_spawned = true

func spawn_mob():
	var new_mob = preload("res://mob.tscn").instantiate()
	%PathFollow2D.progress_ratio = randf()
	new_mob.global_position = %PathFollow2D.global_position
	add_child(new_mob)


func _on_mob_spawn_timer_timeout() -> void:
	spawn_mob()


func _on_player_health_depleted() -> void:
	%GameOver.show()
	end_time = time_passed
	game_over = true
	time_passed = 0.0
	get_tree().paused = true



func _on_button_pressed() -> void:
	get_tree().paused = false
	Autoload.reset_variables()
	reset_game()
	%GameOver.hide()


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


func reset_game():
	# Reset game state
	Autoload.score = 0
	Autoload.level = 1
	time_passed = 0.0
	get_tree().paused = false

	# Reset UI
	%Time.text = "00:00"
	%Score.text = "Level 1 0/..."
	Autoload.add_coins(coins)
	%Coins.text = str(0)
	%LevelProgressBar.value = 0

	# Reset player
	var player = get_node("player")
	print(player.max_health)
	player.health = player.max_health
	player.velocity = Vector2.ZERO
	player.global_position = Vector2(300, 300) # spawn position
	player.get_node("%ProgressBar").value = player.max_health

	# Hide and reset Upgrade Menu or other popups
	%UpgradeMenu.hide()

	# Reset enemies
	for mob in get_tree().get_nodes_in_group("enemies"):
		mob.queue_free()

	# Reset gems and coins
	for drop in get_tree().get_nodes_in_group("drops"):
		drop.queue_free()

	# Reset guns
	for gun in get_tree().get_nodes_in_group("guns"):
		gun.reset() # you define this to hide and disable

	# Reset timers, variables, etc.
	%MobSpawnTimer.start()
