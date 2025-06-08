extends Node2D

var time_passed: float = 0.0
var game_over:bool = false
var end_time:float = 0.0

@onready var game_over_screen = %GameOver
@onready var revive_button = %ReviveButton # Corrected path if ReviveButton is direct child
@onready var revive_timer_label = %ReviveTimerLabel # Corrected path
@onready var revive_countdown_timer = %ReviveCountdownTimer # Corrected path

#const MENU = preload("res://menu.tscn")

var shake_strength:float = 0.0

var bat_spawned: bool = false

@onready var player: CharacterBody2D = $player

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
	game_over_screen.hide()
	%PauseMenu.hide()
	
	for gun in get_tree().get_nodes_in_group("guns"):
		if gun.name == "gun":
			gun.set_process_mode(Node.PROCESS_MODE_DISABLED);
			gun.hide()
	
	
	# Connect the ReviveCountdownTimer's timeout signal
	revive_countdown_timer.timeout.connect(Callable(self, "_on_revive_countdown_timer_timeout"))
	# Connect the ReviveCountdownTimer's `timeout` and also directly update label in `_process`
	# or use a dedicated signal for timer updates if not using `_physics_process` for UI.
	
	# Connect the revive button pressed signal
	revive_button.pressed.connect(Callable(self, "_on_revive_button_pressed"))
	
	# Connect the "No thanks" button (assuming it's %GameOver/Button or similar)
	# You had _on_button_pressed, let's assume that's your "No Thanks" or "Continue" button

	# Set process mode to always even if paused, to ensure timer updates
	revive_countdown_timer.set_process_mode(Node.PROCESS_MODE_ALWAYS)


func _process(delta):
	# Check if ready to level up
	var is_ready_to_level = Autoload.score >= required_xp[level]
	
	# Update revive countdown label if active (only when game is paused and game over screen is visible)
	# This is often more reliable than relying solely on _physics_process for UI updates
	if game_over_screen.visible and get_tree().paused and revive_countdown_timer.time_left > 0:
		var time_left = floor(revive_countdown_timer.time_left) # Floor to get whole seconds
		revive_timer_label.text = "Reviving in: " + str(time_left) + "s"
	elif game_over_screen.visible and get_tree().paused:
		# If timer has run out but screen is still visible, update label
		if Autoload.life_token <= 0: # Only if they couldn't revive
			revive_timer_label.text = "Game Over!" # Or "No tokens available!"
		else:
			revive_timer_label.text = "Time's up!"


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
	
	# The timer label update is moved to _process for better responsiveness.
	# We still keep the check here, but the _process function above is the primary updater now.
	
	if score >= required_xp[level]:
		
		#open level up pop up - PAUSE MENU
		current_selection = 0
		var upgrade_count = 0
		if %Upgrade4.visible:
			upgrade_count = 4 # Corrected assignment from == to =
		else:
			upgrade_count = 3 # Corrected assignment from == to =
		%UpgradeMenu.show()
		%UpgradeButton1.grab_focus()
		assign_upgrades_to_buttons()
		%menu_animations.play("show_menu")
		
		player._update_stats()
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
	
	
	
	# Wave Speed Adjustments
	if time_passed >= 60 and not first_wave_speed:
		%MobSpawnTimer.wait_time = 0.2
		first_wave_speed = true

	if time_passed >= 120 and not second_wave_speed:
		%MobSpawnTimer.wait_time = 1.5 # This looks like a reduction in spawn rate, which is interesting.
		second_wave_speed = true

	if time_passed >= 240 and not third_wave_speed:
		%MobSpawnTimer.wait_time = 0.6
		third_wave_speed = true

	if time_passed >= 480 and not _4th_wave_speed:
		%MobSpawnTimer.wait_time = 0.4
		_4th_wave_speed = true

	# Boss Spawns
	if time_passed >= 300 and not boss1_spawned:
		spawn_boss1()
		boss1_spawned = true

	if time_passed >= 600 and not boss2_spawned:
		spawn_boss2()
		boss2_spawned = true

	if time_passed >= 900 and not boss3_spawned:
		spawn_boss3()
		boss3_spawned = true

	# Specific Mob Spawns (like "bat")
	if time_passed >= 120 and not bat_spawned:
		spawn_mob("bat")
		bat_spawned = true
		# You could also add a temporary increase in spawn rate for this event
		%MobSpawnTimer.wait_time = 0.1 # for a short burst
		# $TemporarySpawnBurstTimer.start(5) # then restore it later


func spawn_mob(group_name: String) -> void:
	#var new_mob = mob_scene.instantiate()
	var new_mob = PoolManager.get_from_pool(group_name)
	if not new_mob: return
	
	%PathFollow2D.progress_ratio = randf()
	new_mob.global_position = %PathFollow2D.global_position
	add_child(new_mob)
	
	if new_mob.has_method("reset"):
		new_mob.reset(group_name)


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



# Called when player health reaches 0
func _on_player_health_depleted() -> void:
	game_over_screen.show() # Always show the Game Over UI
	end_time = time_passed
	game_over = true
	get_tree().paused = true # Pause the game

	# Check for revive tokens and enable/disable revive option
	if Autoload.life_token > 0:
		revive_button.text = "Revive with Token (" + str(Autoload.life_token) + ")"
		revive_button.disabled = false
		revive_button.show()
		revive_timer_label.show()
		revive_countdown_timer.start() # Start the countdown
		print("Player health depleted. Showing revive option.")
	else:
		# No life tokens, just show "Game Over" and disable revive options
		revive_button.hide()
		revive_timer_label.show() # Still show the label
		revive_timer_label.text = "Game Over!"
		revive_countdown_timer.stop() # Ensure timer is stopped
		# Do NOT call finalize_game_over() here immediately.
		# Let the player see the "Game Over!" message and click the "No Thanks" button
		# or wait for the "No Thanks" button's associated timer (if any) to trigger it.
		# If there's no "No Thanks" button and you want it to automatically go to shop after a delay,
		# you'd set up a *separate* timer here for that.
		print("Player health depleted. No revive tokens. Displaying Game Over screen.")



# This function contains the logic for truly ending the game and going to shop/main menu
func finalize_game_over() -> void:
	# Calculate and give XP to Autoload.player_level
	var xp_gained_this_run = Autoload.score / 10 # Example: 10% of score as XP
	Autoload.player_level += int(xp_gained_this_run) # Add XP to permanent player level
	Autoload.save_all_player_data() # Save the updated player_level

	# Now, proceed to the main menu/shop
	Autoload.reset_variables() # This resets in-game stats for a fresh start
	reset_game() # This handles scene specific resets (mobs, gems, player pos)
	
	# Explicitly hide game over screen if it was visible
	game_over_screen.hide()
	
	var main_menu = load("res://shop.tscn") # Assuming this is your main menu/shop
	print("Loaded scene path:", main_menu.resource_path)
	get_tree().change_scene_to_packed(main_menu)




# Called when player clicks "Revive with Token"
func _on_revive_button_pressed() -> void:
	if Autoload.life_token > 0:
		print(Autoload.life_token)
		Autoload.life_token -= 1 # Consume token
		Autoload.save_all_player_data() # Save token change
		
		game_over_screen.hide() # Hide the entire Game Over UI
		revive_countdown_timer.stop() # Stop the timer
		
		var player_node = get_node("player")
		player_node.revive_player() # Trigger player revival logic
		# Ensure the player is unpaused if `revive_player` doesn't handle it
		get_tree().paused = false
		print("Player revived with token.")
	else:
		print("ERROR: Revive button pressed with no tokens. This should have been disabled or hidden!")



func _on_button_pressed() -> void: # This should be your "No Thanks" or "Continue" button
	game_over_screen.hide() # Hide the Game Over UI
	revive_countdown_timer.stop() # Stop the timer
	finalize_game_over() # Proceed to final game over steps
	
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
	time_passed = 0.0
	game_over = false
	get_tree().paused = false

	# Reset UI
	%Time.text = "00:00"
	%Score.text = "Level 1"
	%Coins.text = str(Autoload.player_coins)
	%LevelProgressBar.value = 0

	# Reset player
	var player_node = get_node("player")
	player_node._update_stats()
	player_node.health = player_node.max_health
	player_node.velocity = Vector2.ZERO
	player_node.global_position = Vector2(300, 300)
	player_node.get_node("%ProgressBar").value = player_node.max_health
	player_node.set_physics_process(true)
	player_node.visible = true

	# Hide and reset Upgrade Menu or other popups
	%UpgradeMenu.hide()
	game_over_screen.hide() # Ensure game over screen is hidden

	# Reset enemies (return them to pool)
	for mob in get_tree().get_nodes_in_group("enemies"):
		if mob.has_method("reset") and mob.has_method("_pool_group_name"):
			PoolManager.return_to_pool(mob._pool_group_name, mob)
		else:
			mob.queue_free()

	# Reset gems and coins
	for drop in get_tree().get_nodes_in_group("drops"):
		drop.queue_free()

	# Reset guns
	for gun in get_tree().get_nodes_in_group("guns"):
		gun.set_process_mode(Node.PROCESS_MODE_DISABLED)
		gun.hide()

	for gun in get_tree().get_nodes_in_group("guns"):
		if gun.name == "gun":
			gun.show()
			gun.set_process_mode(Node.PROCESS_MODE_INHERIT)
			break

	# Reset timers, variables, etc.
	%MobSpawnTimer.start()
	first_wave_speed = false
	second_wave_speed = false
	third_wave_speed = false
	_4th_wave_speed = false
	# ... (add other wave flags if necessary) ...
	boss1_spawned = false
	boss2_spawned = false
	boss3_spawned = false
	bat_spawned = false


func _on_pause_button_pressed() -> void:
	get_tree().paused = true
	%PauseMenu.show()


func _on_resume_button_pressed() -> void:
	get_tree().paused = false
	%PauseMenu.hide()
	

func _on_player_revived() -> void:
	get_tree().paused = false # Unpause the game
	%UpgradeMenu.hide() # Ensure upgrade menu is hidden if it was open
	%PauseMenu.hide() # Ensure pause menu is hidden if it was open
	game_over_screen.hide() # NEW: Hide the entire Game Over screen


func _on_revive_countdown_timer_timeout() -> void:
	print("Revive countdown timed out. No revival.")
	# The timer ran out. If they had tokens but didn't click,
	# or if they had no tokens, this leads to the shop.
	finalize_game_over()
