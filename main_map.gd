extends Node2D

var time_passed: float = 0.0
var game_over:bool = false
var end_time:float = 0.0

#const MENU = preload("res://menu.tscn")

var shake_strength:float = 0.0


var level:int = Autoload.level
var required_xp = [
	0,
	40,
	82,
	157,
	238,
	410,
	724,
	1017,
	1548,
	2048,
	2434,
	3312,
	4428,
	5849,
	7657,
	9961,
	12903,
	16521,
	20967,
	26415,
	33066,
	41201,
	51172,
	63312,
	78052,
	95854,
	117707,
	143547,
	174104,
	210234,
	252837,
	302853,
	361279,
	429195,
	507751,
	598177,
	701795,
	820000,
	954293,
	1109531,
	1285706,
	1489114
]

var coins:int = 0

var current_selection:int = 0  # Track selected option
var max_selection = 3  # Assuming there are 4 upgrade options (adjust based on your UI)
var all_upgrades = {
	"Damage": [
		{"desc": "+20% Damage", "apply": func(): Autoload.player_damage_percent += 0.2},
		{"desc": "+15% Damage", "apply": func(): Autoload.player_damage_percent += 0.15},
		{"desc": "+10% Damage", "apply": func(): Autoload.player_damage_percent += 0.1},
		{"desc": "+10% Damage", "apply": func(): Autoload.player_damage_percent += 0.1},
	],
	"Attack Speed": [
		{"desc": "+20% Attack Speed", "apply": func(): Autoload.player_attack_speed -= 0.15},
		{"desc": "+25% Attack Speed", "apply": func(): Autoload.player_attack_speed -= 0.2},
		{"desc": "+20% Attack Speed", "apply": func(): Autoload.player_attack_speed -= 0.15},
		{"desc": "+20% Attack Speed", "apply": func(): Autoload.player_attack_speed -= 0.15},
		{"desc": "+20% Attack Speed", "apply": func(): Autoload.player_attack_speed -= 0.15},
		{"desc": "+20% Attack Speed", "apply": func(): Autoload.player_attack_speed -= 0.15},
		{"desc": "+20% Attack Speed", "apply": func(): Autoload.player_attack_speed -= 0.15},
	],
	"Move Speed": [
		{"desc": "+30% Move Speed", "apply": func(): Autoload.player_speed_percent += 0.3},
		{"desc": "+20% Move Speed", "apply": func(): Autoload.player_speed_percent += 0.2},
		{"desc": "+20% Move Speed", "apply": func(): Autoload.player_speed_percent += 0.2},
		{"desc": "+20% Move Speed", "apply": func(): Autoload.player_speed_percent += 0.2},
	],
	"Crit Chance": [
		{"desc": "+5% Crit Chance", "apply": func(): Autoload.crit_chance += 0.05},
		{"desc": "+5% Crit Chance", "apply": func(): Autoload.crit_chance += 0.05},
		{"desc": "+10% Crit Chance", "apply": func(): Autoload.crit_chance += 0.1},
		{"desc": "+10% Crit Chance", "apply": func(): Autoload.crit_chance += 0.1},
	],
	"Bullet Size": [
		{"desc": "+15% Bullet Size", "apply": func(): Autoload.bullet_scale += 0.15},
	],
	"Health": [
		{"desc": "+20% Max Health", "apply": func(): apply_health_upgrade()},
		{"desc": "+20% Max Health", "apply": func(): apply_health_upgrade()},
		{"desc": "+20% Max Health", "apply": func(): apply_health_upgrade()},
	],
	"Luck": [
		{"desc": "+20% Luck", "apply": func(): Autoload.player_luck_percent += 0.2},
		{"desc": "+20% Luck", "apply": func(): Autoload.player_luck_percent += 0.2},
	],
	"Health Regen": [
		{ "desc": "Regenerate 2 HP per second", "apply": func(): Autoload.health_regen += 1},
		{ "desc": "Regenerate 2 HP per second", "apply": func(): Autoload.health_regen += 1},
	],
	"Gun 1": [
		{"desc": "Gun (New)", "apply": func(): gun1_activate()},
		{"desc": "+1 Bullet", "apply": func(): Autoload.gun1_bullets += 1},
		{"desc": "+20% Fire Rate", "apply": func(): Autoload.gun1_attack_speed += 0.2},
	],
	"Gun 2": [
		{"desc": "Gun (New)", "apply": func(): gun2_activate()},
		{"desc": "+1 Bullet (Gun 2)", "apply": func(): Autoload.gun2_bullets += 1},
	],
	"Gun 3": [
		{"desc": "Gun (New)", "apply": func(): gun3_activate()},
		{"desc": "+1 Bullet (Gun 3)", "apply": func(): Autoload.gun3_bullets += 1},
	],
	"Gun 4": [
		{"desc": "Gun (New)", "apply": func(): gun4_activate()},
		{"desc": "+1 Bullet (Gun 4)", "apply": func(): Autoload.gun4_bullets += 1},
	],
	"Gun 5": [
		{"desc": "Gun (New)", "apply": func(): gun5_activate()},
		{"desc": "+1 Bullet (Gun 5)", "apply": func(): Autoload.gun5_bullets += 1},
	],
	"Gun 6": [
		{"desc": "Gun (New)", "apply": func(): gun6_activate()},
		{"desc": "+1 Bullet (Gun 6)", "apply": func(): Autoload.gun6_bullets += 1},
	],
	"Shotgun": [
		#{"desc": "Unlock Shotgun", "apply": func(): gun6_activate()},
		{"desc": "+1 Magazine", "apply": func(): Autoload.shotgun_magazine += 1},
		{"desc": "-0.1sec Attack Cooldown", "apply": func(): Autoload.shotgun_cooldown -= 0.1},
		{"desc": "+100% Damage", "apply": func(): Autoload.shotgun_base_damage += 20},
		{"desc": "+1 Magazine", "apply": func(): Autoload.shotgun_magazine += 1},
		{"desc": "-0.5sec Reload", "apply": func(): Autoload.shotgun_reload_duration -= 0.5},
		{"desc": "+1 Magazine", "apply": func(): Autoload.shotgun_magazine += 1},
		{"desc": "-0.5sec Reload", "apply": func(): Autoload.shotgun_reload_duration -= 0.5},
		{"desc": "+1 Magazine", "apply": func(): Autoload.shotgun_magazine += 1},
		{"desc": "+50% Range", "apply": func(): Autoload.shotgun_bullet_range += 250},
	],
	# Crown, Penetration
}

var upgrade_levels = {
	"Attack Speed": 1,
	"Health Regen": 1,
	"Crit Chance": 0,
	"Gun 1": 0,
	"Gun 2": 0,
}  # e.g., {"Damage": 1, "Crit Chance": 2}


var easy_wave_spawned:bool = false
var medium_wave_spawned:bool = false
var hard_wave_spawned:bool = false
var boss1_spawned:bool = false
var boss2_spawned:bool = false
var boss3_spawned:bool = false

const MOB_EASY = preload("res://mob.tscn")
const MOB_MEDIUM = preload("res://python.tscn")
const MOB_HARD = preload("res://psycho.tscn")
const BOSS_1 = preload("res://boss_10.tscn")
const BOSS_2 = preload("res://bull-boss10.tscn")
const BOSS_3 = preload("res://giant-boss-20.tscn")

var first_wave_speed: bool = false
var second_wave_speed: bool = false
var third_wave_speed: bool = false
var _4th_wave_speed: bool = false
var _5h_wave_speed: bool = false
var _6th_wave_speed: bool = false
var _7th_wave_speed: bool = false
var _8th_wave_speed: bool = false


func _ready() -> void:
	randomize()
	for skill in all_upgrades.keys():
		upgrade_levels[skill] = 0

	%UpgradeMenu.hide()
	$Score/DebugUI.hide()
	%GameOver.hide()
	%PauseMenu.hide()
	
	for gun in get_tree().get_nodes_in_group("guns"):
		if gun.name == "gun":
			gun.set_process_mode(Node.PROCESS_MODE_DISABLED);
			gun.hide()


func _process(delta):


	# Check if ready to level up
	var is_ready_to_level = Autoload.score >= required_xp[level]



func gun1_activate():
	for gun in get_tree().get_nodes_in_group("guns"):
		if gun.name == "gun":
			gun.set_process_mode(Node.PROCESS_MODE_INHERIT);
			gun.show()

func gun2_activate():
	%gun2.set_process_mode(Node.PROCESS_MODE_INHERIT);
	%gun2.show()

func gun3_activate():
	%gun3.set_process_mode(Node.PROCESS_MODE_INHERIT);
	%gun3.show()

func gun4_activate():
	%gun4.set_process_mode(Node.PROCESS_MODE_INHERIT);
	%gun4.show()

func gun5_activate():
	%gun5.set_process_mode(Node.PROCESS_MODE_INHERIT);
	%gun5.show()

func gun6_activate():
	%gun6.set_process_mode(Node.PROCESS_MODE_INHERIT);
	%gun6.show()


func apply_health_upgrade():
	var player = get_node("player")
	player.max_health = int(player.max_health * 1.2)
	player.health = player.max_health
	player.get_node("%ProgressBar").max_value = player.max_health
	player.get_node("%ProgressBar").value = player.health


func handle_upgrade_input():
	#if not %UpgradeMenu.visible:
		#return
		#print("shit works")
	var max_selection = 3
	if %Upgrade4.visible:
		max_selection = 4
	
	#Navigate
	if Input.is_action_just_pressed("move_up"):
		current_selection = max(current_selection - 1, 0)
	elif Input.is_action_just_pressed("move_down"):
		current_selection = min(current_selection + 1, max_selection - 1)
	else:
		print("nah")
	
	# Select
	if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("enter") or Input.is_action_just_pressed("space"):
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
		print(current_selection)
		upgrades[i].modulate = Color.YELLOW if i == current_selection else Color.WHITE


# Shake effect
#func apply_shake(amount):
	#shake_strength = amount
#
#
#func _process(delta: float) -> void:
	#if shake_strength > 0:
		#offset = Vector2(randf() - 0.5, randf() - 0.5) * shake_strength
		#shake_strength = lerp(shake_strength, 0, delta * 10)
	#else:
		#offset = Vector2.ZERO


func _physics_process(delta: float) -> void:
	Autoload.level = level
	var score = Autoload.score
	%LevelProgressBar.value = score - required_xp[level - 1]
	%LevelProgressBar.max_value = required_xp[level] - required_xp[level - 1]
	#%Score.text = "Level " + str(level) + " " + str(score) + "/" + str(required_xp[level])
	%Score.text = "Level " + str(level)
	
	if score >= required_xp[level]:
		#open level up pop up - PAUSE MENU
		current_selection = 0
		var upgrade_count = 0
		if %Upgrade4.visible:
			upgrade_count == 4
		else:
			upgrade_count == 3
		%UpgradeMenu.show()
		%UpgradeButton1.grab_focus()
		assign_upgrades_to_buttons()
		%menu_animations.play("show_menu")
		
		
		get_tree().paused = true
		level += 1
	#if level == 2:
		#%MobSpawnTimer.wait_time = 0.8
	#elif level == 3:
		#%MobSpawnTimer.wait_time = 0.4
		#%gun2.set_process_mode(Node.PROCESS_MODE_INHERIT)
		#%gun2.show()
	#elif level == 4:
		#%MobSpawnTimer.wait_time = 0.25
		#%gun3.set_process_mode(Node.PROCESS_MODE_INHERIT)
		#%gun3.show()
	#elif level == 5:
		#%MobSpawnTimer.wait_time = 0.17
		#%gun4.set_process_mode(Node.PROCESS_MODE_INHERIT)
		#%gun4.show()
	#elif level == 6:
		#%MobSpawnTimer.wait_time = 0.14
		#%gun5.set_process_mode(Node.PROCESS_MODE_INHERIT)
		#%gun5.show()
	#elif level == 7:
		#%MobSpawnTimer.wait_time = 0.13
		#%gun6.set_process_mode(Node.PROCESS_MODE_INHERIT)
		#%gun6.show()
	
	
	if not get_tree().paused and not game_over:
		time_passed += delta
	
	var minutes = int(time_passed) / 60
	var seconds = int(time_passed) % 60
	%Time.text = "%02d:%02d" % [minutes, seconds]
	#print(coins)
	%Coins.text = str(Autoload.player_coins)
	
	if not boss1_spawned and time_passed >= 300:
		spawn_boss1()
	elif time_passed >= 60 and not first_wave_speed:
		%MobSpawnTimer.wait_time = 0.2
		first_wave_speed = true
	elif time_passed >= 120 and not second_wave_speed:
		%MobSpawnTimer.wait_time = 1.5
		second_wave_speed = true
	elif time_passed >= 240 and not third_wave_speed:
		%MobSpawnTimer.wait_time = 0.6
		third_wave_speed = true
	elif time_passed >= 480 and not _4th_wave_speed:
		%MobSpawnTimer.wait_time = 0.4
		_4th_wave_speed = true
	elif not boss2_spawned and time_passed >= 600:
		spawn_boss2()
	elif not boss3_spawned and time_passed >= 900:
		spawn_boss3()


func spawn_mob(group_name: String) -> void:
	#var new_mob = mob_scene.instantiate()
	var new_mob = PoolManager.get_from_pool(group_name)
	if not new_mob: return
	
	%PathFollow2D.progress_ratio = randf()
	new_mob.global_position = %PathFollow2D.global_position
	add_child(new_mob)
	
	if new_mob.has_method("reset"):
		new_mob.reset()


# Spawning logic
func spawn_easy_wave():
	spawn_mob("mob")
	easy_wave_spawned = true

func spawn_medium_wave():
	spawn_mob("python")
	medium_wave_spawned = true

func spawn_hard_wave():
	spawn_mob("psycho")
	hard_wave_spawned = true

func spawn_boss1():
	spawn_mob("bull_boss")
	boss1_spawned = true

func spawn_boss2():
	spawn_mob("giant_boss")
	boss2_spawned = true

func spawn_boss3():
	spawn_mob("boss1")
	boss3_spawned = true


func _on_mob_spawn_timer_timeout() -> void:
	if time_passed > 0 and time_passed < 120:
		spawn_easy_wave()
	elif time_passed < 240 and time_passed > 120:
		spawn_medium_wave()
	elif time_passed < 480 and time_passed > 240:
		spawn_hard_wave()


func _on_player_health_depleted() -> void:
	%GameOver.show()
	end_time = time_passed
	game_over = true
	time_passed = 0.0
	get_tree().paused = true



func _on_button_pressed() -> void:
	Autoload.reset_variables()
	reset_game()
	%GameOver.hide()
	var main_menu = load("res://menu.tscn")
	print("Loaded scene path:", main_menu.resource_path)
	get_tree().change_scene_to_packed(main_menu)
	
	# Load main menu


#-----------------------------------------------------
#UPGRADES
#-----------------------------------------------------


func assign_upgrades_to_buttons():
	var upgrade_buttons = [%UpgradeButton1, %UpgradeButton2, %UpgradeButton3, %UpgradeButton4]
	var upgrade_labels = [%Upgrade1text, %Upgrade2text, %Upgrade3text, %Upgrade4text]
	var upgrade_descs = [%UpgradeDesc1, %UpgradeDesc2, %UpgradeDesc3, %UpgradeDesc4]
	
	# How many upgrades to show? If Upgrade4 isn't visible, only 3.
	var count = upgrade_buttons.size()
	if not %Upgrade4.visible:
		count = 3
	
	
	var upgrade_keys = all_upgrades.keys()
	upgrade_keys.shuffle()
	
	
	var filled = 0
	var i = 0
	while filled < count and i < upgrade_keys.size():
		var upgrade_type = upgrade_keys[i]
		var level = upgrade_levels.get(upgrade_type, 0)
		var upgrade_data = all_upgrades[upgrade_type]

		if level < upgrade_data.size():
			var upgrade = upgrade_data[level]
			upgrade_buttons[filled].set_meta("upgrade_type", upgrade_type)
			upgrade_buttons[filled].set_meta("upgrade_level", level)
			upgrade_labels[filled].text = upgrade_type
			upgrade_descs[filled].text = upgrade["desc"]
			filled += 1
		i += 1



func apply_upgrade(button):
	var type = button.get_meta("upgrade_type")
	var level = button.get_meta("upgrade_level")
	
	var upgrade = all_upgrades[type][level]
	if "apply" in upgrade and upgrade["apply"] is Callable:
		upgrade["apply"].call()
	else:
		push_error("Missing or invalid 'apply' for upgrade: %s" % type)
	
	upgrade_levels[type] = upgrade_levels.get(type, 0) + 1
	%UpgradeMenu.hide()
	get_tree().paused = false


func _on_upgrade_button_1_pressed() -> void:
	apply_upgrade(%UpgradeButton1)

func _on_upgrade_button_2_pressed() -> void:
	apply_upgrade(%UpgradeButton2)

func _on_upgrade_button_3_pressed() -> void:
	apply_upgrade(%UpgradeButton3)

func _on_upgrade_button_4_pressed() -> void:
	apply_upgrade(%UpgradeButton4)



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
	#%Coins.text = str(0)
	%LevelProgressBar.value = 0

	# Reset player
	var player = get_node("player")
	#print(player.max_health)
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
		if gun.name == "gun":
			gun.show()
			gun.set_process_mode(Node.PROCESS_MODE_INHERIT);
			continue
			
		gun.set_process_mode(Node.PROCESS_MODE_DISABLED);
		gun.hide() # you define this to hide and disable
		
	
	# Reset timers, variables, etc.
	%MobSpawnTimer.start()


#func _on_menu_animations_animation_finished(anim_name: StringName) -> void:
	#if anim_name == "show_menu":
		#%UpgradeMenu.show()
		#print("showed")


func _on_pause_button_pressed() -> void:
	get_tree().paused = true
	%PauseMenu.show()


func _on_resume_button_pressed() -> void:
	get_tree().paused = false
	%PauseMenu.hide()
	
