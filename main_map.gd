extends Node2D

@onready var game_over_screen = %GameOver
@onready var revive_button = %ReviveButton
@onready var revive_timer_label = %ReviveTimerLabel
@onready var revive_countdown_timer = %ReviveCountdownTimer

var shake_strength:float = 0.0

var bat_spawned: bool = false # Declare this here

var time_passed: float = 0.0
var game_over: bool = false
var end_time: float = 0.0 # This variable is mostly superseded by game_duration
var game_duration: float = 600.0 # 10 minutes (600 seconds)


@onready var game_music_player = %GameMusicPlayer # Your main game music player
@onready var pause_menu_music_player = %PauseMenuMusicPlayer

@onready var player_animations: AnimationPlayer = %player_animations

@onready var game_timer_label = %Time # Assuming your game time display is named 'Time'
@onready var player: CharacterBody2D = $player # Ensure this path is correct

@onready var upgrade_menu = %UpgradeMenu # Correct: Matches image
# Corrected paths for upgrade buttons and their labels/descriptions based on image
@onready var upgrade_button1 = %UpgradeButton1
@onready var upgrade_button2 = %UpgradeButton2
@onready var upgrade_button3 = %UpgradeButton3
@onready var upgrade_button4 = %UpgradeButton4 # If you have a 4th button

@onready var upgrade_text1 = %Upgrade1text
@onready var upgrade_text2 = %Upgrade2text
@onready var upgrade_text3 = %Upgrade3text
@onready var upgrade_text4 = %Upgrade4text # If you have a 4th button

@onready var upgrade_desc1 = %UpgradeDesc1
@onready var upgrade_desc2 = %UpgradeDesc2
@onready var upgrade_desc3 = %UpgradeDesc3
@onready var upgrade_desc4 = %UpgradeDesc4 # If you have a 4th button

@onready var menu_animations = %menu_animations # Assuming an AnimationPlayer for menu animations

@onready var coins_label = %Coins # Assuming your coins label
@onready var gems_label = %Gems # Assuming your gems label
@onready var level_progress_bar = %LevelProgressBar # Correct: Matches image
@onready var score_label = %Score # Correct: Matches image (the "Level X" label)

@onready var pause_button = %PauseButton # Assuming your pause button
@onready var pause_menu = %PauseMenu # Assuming your pause menu node
@onready var resume_button = %ResumeButton # Assuming your resume button

# Game Juice related nodes
@onready var camera_2d = %Camera2D # Assuming your Camera2D node is a child of Gameplay
@onready var level_up_fx = %LevelUpFX # Assuming you have a node for level up visual effects (e.g., AnimationPlayer)
@onready var game_win_screen = %GameWinScreen # Assuming you have a CanvasLayer/Control node for the win screen
@onready var sfx_player = %SFXPlayer # Add an AudioStreamPlayer node named 'SFXPlayer'

# Dynamic Enemy Spawning
const REGULAR_ENEMY_TYPES = ["mob", "python", "psycho", "bat"] # Ensure these match your Pool_manager.gd
const BOSS_ENEMY_TYPES = ["boss1", "bull_boss", "giant_boss"] # Ensure these match your Pool_manager.gd
var current_enemy_type_index: int = 0
var current_boss_type_index: int = 0

@onready var mob_spawn_timer = %MobSpawnTimer # Correct: Matches image
@onready var enemy_type_change_timer = %EnemyTypeChangeTimer # New: Timer to change regular enemy type (set wait_time to 60 in editor)
@onready var boss_spawn_timer = %BossSpawnTimer # New: Timer to spawn bosses (set wait_time to 180 in editor)
@onready var path_follow_2d = %PathFollow2D # Assuming your MobPath is a Path2D with a PathFollow2D

# Signals for game juice
signal screen_shake_requested(strength: float, duration: float)
signal play_sfx(sfx_name: String) # For general sound effects



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

var current_selection:int = 0
var max_selection = 3
var all_upgrades = {
	"Damage": [
		{"desc": "+20% Damage", "apply": func(): Autoload.player_damage_percent += 0.2},
		{"desc": "+15% Damage", "apply": func(): Autoload.player_damage_percent += 0.15},
		{"desc": "+10% Damage", "apply": func(): Autoload.player_damage_percent += 0.1},
		{"desc": "+10% Damage", "apply": func(): Autoload.player_damage_percent += 0.1},
	],
	"Attack Speed": [
		{"desc": "+20% Attack Speed", "apply": func(): Autoload.player_attack_speed -= 0.15}, # Lower is faster
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
		{"desc": "Regenerate 1 HP per second", "apply": func(): Autoload.health_regen += 1}, # Adjusted for consistency
		{"desc": "Regenerate 1 HP per second", "apply": func(): Autoload.health_regen += 1},
	],
	"Rifle": [ # Changed from "Gun 1"
		{"desc": "Rifle (New)", "apply": func(): rifle_activate()},
		{"desc": "+1 Bullet (Rifle)", "apply": func(): Autoload.rifle_bullets += 1},
		{"desc": "-10% Fire Rate (Rifle)", "apply": func(): Autoload.rifle_attack_speed *= 0.9}, # Faster fire rate
	],
	"Shotgun": [ # Renamed from "Gun 2", added activation
		{"desc": "Shotgun (New)", "apply": func(): shotgun_activate()},
		{"desc": "+1 Bullet (Shotgun)", "apply": func(): Autoload.shotgun_bullets += 1},
		{"desc": "+1 Magazine (Shotgun)", "apply": func(): Autoload.shotgun_magazine += 1},
		{"desc": "-0.05sec Attack Cooldown", "apply": func(): Autoload.shotgun_cooldown -= 0.05},
		{"desc": "+10 Damage", "apply": func(): Autoload.shotgun_base_damage += 10},
		{"desc": "-0.2sec Reload", "apply": func(): Autoload.shotgun_reload_duration -= 0.2},
		{"desc": "+100 Range", "apply": func(): Autoload.shotgun_bullet_range += 100},
	],
	"Machine Gun": [ # Changed from "Gun 3"
		{"desc": "Machine Gun (New)", "apply": func(): machinegun_activate()},
		{"desc": "+1 Bullet (Machine Gun)", "apply": func(): Autoload.machinegun_bullets += 1},
	],
	"Laser": [ # Changed from "Gun 4"
		{"desc": "Laser (New)", "apply": func(): laser_activate()},
		{"desc": "+1 Bullet (Laser)", "apply": func(): Autoload.laser_bullets += 1},
	],
	"Rocket": [ # Changed from "Gun 5"
		{"desc": "Rocket Launcher (New)", "apply": func(): rocket_activate()},
		{"desc": "+1 Bullet (Rocket)", "apply": func(): Autoload.rocket_bullets += 1},
	],
	"Flamethrower": [ # Changed from "Gun 6"
		{"desc": "Flamethrower (New)", "apply": func(): flamethrower_activate()},
		{"desc": "+1 Bullet (Flamethrower)", "apply": func(): Autoload.flamethrower_bullets += 1},
	],
}


var upgrade_levels = {
	#Passives
	"Damage": 0,
	"Attack Speed": 0,
	"Move Speed": 0,
	"Crit Chance": 0,
	"Bullet Size": 0,
	"Health": 0,
	"Luck": 0,
	"Health Regen": 0,
	
	#Active guns
	"Rifle": 0,
	"Shotgun": 1,
	"Machine Gun": 0,
	"Laser": 0,
	"Rocket": 0,
	"Flamethrower": 0,
	"Shockwave": 0,
}


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

	upgrade_menu.hide()
	# $Score/DebugUI.hide() # Uncomment if you have a debug UI
	game_over_screen.hide()
	pause_menu.hide()
	game_win_screen.hide() # Hide win screen initially
	%"Level-up-fx".hide() # Hide level up FX initially
	
	
	# Initialize music
	if game_music_player:
		game_music_player.play()
	if pause_menu_music_player:
		pause_menu_music_player.stop()
	
	
	# Connect player signals
	if player:
		player.health_depleted.connect(Callable(self, "_on_player_health_depleted"))
		player.revived.connect(Callable(self, "_on_player_revived"))
		player.player_hit.connect(Callable(self, "_on_player_hit"))
		player.gem_collected.connect(Callable(self, "_on_player_gem_collected"))
	else:
		push_error("Player node not found! Check @onready var player path.")

	# Connect to the screen shake signal for the camera
	if camera_2d and camera_2d.has_method("start_shake"):
		screen_shake_requested.connect(Callable(camera_2d, "start_shake"))
	else:
		push_error("Camera2D or start_shake method not found for screen shake!")

	# Connect to the sound effect signal for SFXPlayer
	if sfx_player:
		play_sfx.connect(Callable(self, "_on_play_sfx_requested"))
	else:
		push_error("SFXPlayer node not found! Audio will not play.")

	# Hide initial guns (adjust based on your actual gun scene names)
	for gun in get_tree().get_nodes_in_group("guns"):
		if gun.name == "shotgun": # Your starting gun should have the name "Rifle"
			gun.set_process_mode(Node.PROCESS_MODE_INHERIT)
			gun.show()
		else:
			gun.set_process_mode(Node.PROCESS_MODE_DISABLED)
			gun.hide()

	# Connect ReviveCountdownTimer's timeout signal and revive button
	revive_countdown_timer.timeout.connect(Callable(self, "_on_revive_countdown_timer_timeout"))
	revive_button.pressed.connect(Callable(self, "_on_revive_button_pressed"))

	# Ensure UI elements that need to update during pause are set to PROCESS_MODE_ALWAYS
	revive_countdown_timer.set_process_mode(Node.PROCESS_MODE_ALWAYS)
	game_over_screen.set_process_mode(Node.PROCESS_MODE_ALWAYS)
	revive_timer_label.set_process_mode(Node.PROCESS_MODE_ALWAYS)
	revive_button.set_process_mode(Node.PROCESS_MODE_ALWAYS)
	pause_menu.set_process_mode(Node.PROCESS_MODE_ALWAYS) # To allow pausing functionality

	# Initialize dynamic enemy spawning
	_select_next_enemy_type() # Select initial enemy type
	enemy_type_change_timer.start() # Start the timer for changing enemy types

	boss_spawn_timer.start() # Start the timer for spawning bosses

	# Connect dynamic enemy timers
	enemy_type_change_timer.timeout.connect(Callable(self, "_on_enemy_type_change_timer_timeout"))
	boss_spawn_timer.timeout.connect(Callable(self, "_on_boss_spawn_timer_timeout"))

	# Connect upgrade buttons
	upgrade_button1.pressed.connect(Callable(self, "_on_upgrade_button_1_pressed"))
	upgrade_button2.pressed.connect(Callable(self, "_on_upgrade_button_2_pressed"))
	upgrade_button3.pressed.connect(Callable(self, "_on_upgrade_button_3_pressed"))
	if upgrade_button4: # Only connect if you have a 4th button
		upgrade_button4.pressed.connect(Callable(self, "_on_upgrade_button_4_pressed"))

	# Connect pause and resume buttons
	pause_button.pressed.connect(Callable(self, "_on_pause_button_pressed"))
	resume_button.pressed.connect(Callable(self, "_on_resume_button_pressed"))
	# Assuming your game_over_screen has a button to return to main menu/shop
	# connect that button's pressed signal to _on_return_to_main_menu_button_pressed()
	# Or for game_win_screen a similar button.



func _process(delta):
	# _process will only run when the game is NOT paused.
	if not get_tree().paused:
		time_passed += delta
		var minutes = int(time_passed) / 60
		var seconds = int(time_passed) % 60
		game_timer_label.text = "%02d:%02d" % [minutes, seconds]
		coins_label.text = str(Autoload.player_coins)
		gems_label.text = str(Autoload.player_gems) # Display current run gems

		# Check for game over based on time limit
		if time_passed >= game_duration and not game_over:
			_on_game_duration_end()
			game_over = true # Prevent further time updates
			get_tree().paused = true # Pause the game to show win screen
			game_win_screen.show() # Display the "You Win!" screen
			emit_signal("play_sfx", "game_win") # Play win sound


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
	var player_node = get_node("player")
	if player_node: # Ensure player exists
		player_node.max_health = int(player_node.max_health * 1.2)
		player_node.health = player_node.max_health
		player_node.get_node("%ProgressBar").max_value = player_node.max_health
		player_node.get_node("%ProgressBar").value = player_node.health
		emit_signal("play_sfx", "upgrade_health") # Play health upgrade sound


func handle_upgrade_input():
	var max_selection = 3
	if upgrade_button4 and upgrade_button4.visible: # Check if button4 exists and is visible
		max_selection = 4

	if Input.is_action_just_pressed("move_up"):
		current_selection = max(current_selection - 1, 0)
		emit_signal("play_sfx", "ui_hover") # Play UI hover sound
	elif Input.is_action_just_pressed("move_down"):
		current_selection = min(current_selection + 1, max_selection - 1)
		emit_signal("play_sfx", "ui_hover") # Play UI hover sound
	else:
		pass

	if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("enter") or Input.is_action_just_pressed("space"):
		emit_signal("play_sfx", "ui_select") # Play UI select sound
		match current_selection:
			0: upgrade_button1.emit_signal("pressed")
			1: upgrade_button2.emit_signal("pressed")
			2: upgrade_button3.emit_signal("pressed")
			3:
				if max_selection == 4:
					upgrade_button4.emit_signal("pressed")






func _physics_process(delta: float) -> void:
	# This will pause when get_tree().paused is true.
	if not get_tree().paused:
		Autoload.level = level
		var score = Autoload.score
		level_progress_bar.value = score - required_xp[level - 1]
		level_progress_bar.max_value = required_xp[level] - required_xp[level - 1]
		score_label.text = "Level " + str(level)

		# Check for level up ONLY if the game is NOT paused
		if level < required_xp.size() and score >= required_xp[level]:
			current_selection = 0
			player.set_physics_process(false)
			upgrade_menu.show()
			upgrade_button1.grab_focus()
			assign_upgrades_to_buttons()
			menu_animations.play("show_menu")
			emit_signal("play_sfx", "level_up") # Play level up sound
			player._update_stats() # Assuming player has this to refresh stats
			get_tree().paused = true # Pause the game *after* showing the upgrade menu
			level += 1
			%"Level-up-fx".show() # Show level up FX
			if level_up_fx.has_method("play"): # If it's an AnimationPlayer
				level_up_fx.play("upgrade_idle") # Play an animation to fade out the FX




# --- NEW: Dynamic Enemy Spawning Functions ---
func _select_next_enemy_type():
	current_enemy_type_index = (current_enemy_type_index + 1) % REGULAR_ENEMY_TYPES.size()
	var selected_type = REGULAR_ENEMY_TYPES[current_enemy_type_index]
	print("DEBUG: Next regular enemy type: ", selected_type)
	# You might want to adjust mob spawn timer based on difficulty of new enemy type here
	# For now, we'll keep the %MobSpawnTimer.wait_time as it is for general density.

func _select_next_boss_type():
	current_boss_type_index = (current_boss_type_index + 1) % BOSS_ENEMY_TYPES.size()
	var selected_type = BOSS_ENEMY_TYPES[current_boss_type_index]
	print("DEBUG: Next boss type: ", selected_type)


func _on_enemy_type_change_timer_timeout():
	_select_next_enemy_type()


func _on_boss_spawn_timer_timeout():
	_select_next_boss_type()
	spawn_mob(BOSS_ENEMY_TYPES[current_boss_type_index])
	emit_signal("play_sfx", "boss_spawn") # Play boss spawn sound (you'll need this SFX)


func spawn_mob(group_name: String) -> void:
	var new_mob = PoolManager.get_from_pool(group_name)
	if not new_mob:
		print("WARNING: No mob of type found in pool: ",group_name)
		return

	path_follow_2d.progress_ratio = randf() # Assuming you use a Path2D for spawning
	new_mob.global_position = path_follow_2d.global_position
	add_child(new_mob)

	if new_mob.has_method("reset"): # Assuming your mob script has a reset function
		new_mob.reset(group_name) # Call reset if it's a pooled mob
	if new_mob.has_method("set_pool_group_name"): # Set pool group name for returning later
		new_mob.set_pool_group_name(group_name)

# Modified: Use current_enemy_type
func _on_mob_spawn_timer_timeout() -> void:
	# Spawn the currently selected regular enemy type
	spawn_mob(REGULAR_ENEMY_TYPES[current_enemy_type_index])


# --- NEW: Game Juice Functions ---
# Connects to player.player_hit signal
func _on_player_hit():
	emit_signal("screen_shake_requested", 5.0, 0.2) # Small shake on player hit
	# SFX already emitted by _on_play_sfx_requested when player_hit is emitted.


# Connects to player.gem_collected signal
func _on_player_gem_collected(amount: int):
	Autoload.add_gems(amount) # Call Autoload's function to update current run's gems
	# SFX already emitted by _on_play_sfx_requested when gem_collect is emitted.
	#pass	


# This function handles playing sound effects via the SFXPlayer node
func _on_play_sfx_requested(sfx_name: String):
	# You NEED to create these audio files in your project and replace paths
	# Example paths, adjust to your actual project structure:
	var sfx_path = ""
	match sfx_name:
		"level_up": sfx_path = "res://assets/SFX/level-up-289723.ogg"
		"player_hit": sfx_path = "res://assets/SFX/slap-hurt-pain-sound-effect-262618.mp3"
		"upgrade_health": sfx_path = "res://assets/SFX/172589__qubodup__health-potion-166188-drminky-potion-drink-regen.ogg"
		"upgrade_apply": sfx_path = "res://assets/SFX/734842__muna_alaneme__upgrade-sound-0001.wav"
		"ui_hover": sfx_path = "res://assets/SFX/ui-hover.wav"
		"ui_select": sfx_path = "res://assets/SFX/ui-select.ogg"
		"ui_pause": sfx_path = "res://assets/SFX/ui-select.ogg"
		"ui_resume": sfx_path = "res://assets/SFX/unpause.ogg"
		"player_death": sfx_path = "res://assets/SFX/arcade-game-over.ogg"
		"revive": sfx_path = "res://assets/SFX/Revive - Celestial Metal Resurrection Chime.ogg"
		"gem_collect": sfx_path = "res://assets/SFX/Sparkling Gem Collection Sound.ogg"
		"game_win": sfx_path = "res://assets/SFX/win_sfx.ogg"
		"boss_spawn": sfx_path = "res://assets/SFX/final_bell.mp3" # New SFX for boss
		# Add more SFX paths as needed
	if sfx_path and sfx_player:
		var audio_stream = load(sfx_path)
		if audio_stream:
			sfx_player.stream = audio_stream
			sfx_player.play()
		else:
			push_error("Could not load audio stream from ",sfx_path)
	else:
		# This could happen if SFXPlayer is null or sfx_name is not matched
		print("WARNING: No SFX path for ... or SFXPlayer not available: ",sfx_name)


# --- Gun Activation Functions (adapted to new names) ---
func rifle_activate(): # Changed from gun1_activate
	for gun in get_tree().get_nodes_in_group("guns"):
		if gun.name == "Rifle": # Ensure this matches your gun scene name (e.g. your pistol)
			gun.set_process_mode(Node.PROCESS_MODE_INHERIT);
			gun.show()

func shotgun_activate():
	%shotgun.set_process_mode(Node.PROCESS_MODE_INHERIT); # Match your Shotgun node name
	%shotgun.show()

func machinegun_activate():
	%MachineGun.set_process_mode(Node.PROCESS_MODE_INHERIT); # Match your MachineGun node name
	%MachineGun.show()

func laser_activate():
	%Laser.set_process_mode(Node.PROCESS_MODE_INHERIT); # Match your Laser node name
	%Laser.show()

func rocket_activate():
	%RocketLauncher.set_process_mode(Node.PROCESS_MODE_INHERIT); # Match your RocketLauncher node name
	%RocketLauncher.show()

func flamethrower_activate():
	%Flamethrower.set_process_mode(Node.PROCESS_MODE_INHERIT); # Match your Flamethrower node name
	%Flamethrower.show()


func shockwave_activate():
	%Shockwave.set_process_mode(Node.PROCESS_MODE_INHERIT); # Match your Flamethrower node name
	%Shockwave.show()




func _on_player_health_depleted() -> void:
	print("--- TRACE (Gameplay): _on_player_health_depleted() ENTRY ---")
	game_over_screen.show()
	print("TRACE (Gameplay): After game_over_screen.show(), game_over_screen.is_visible() = ", game_over_screen.is_visible())

	end_time = time_passed # Store time of death
	game_over = true # Set game_over flag

	get_tree().paused = true # Pause the game
	print("TRACE (Gameplay): After setting get_tree().paused = true, CURRENTLY it is: ", get_tree().paused)

	player.set_physics_process(false)
	emit_signal("play_sfx", "player_death") # Play player death sound

	if player_animations:
		player_animations.play("Death") # Assuming "Death" is your player death animation
		player_animations.queue("Idle") # Queue idle after death animation if it's short


	if Autoload.life_token > 0:
		revive_button.text = "Revive with Token (" + str(Autoload.life_token) + ")"
		revive_button.disabled = false
		revive_button.show()
		revive_timer_label.show()
		revive_countdown_timer.start()
		print("TRACE (Gameplay): Player health depleted. Showing revive option. Timer started.")
	else:
		revive_button.hide()
		revive_timer_label.show()
		revive_timer_label.text = "Game Over!" # Final text here
		revive_countdown_timer.stop()
		print("TRACE (Gameplay): Player health depleted. No revive tokens. Displaying Game Over screen.")

	print("--- TRACE (Gameplay): _on_player_health_depleted() EXIT ---")


func finalize_game_over() -> void:
	var xp_gained_this_run = Autoload.score / 10 # Example conversion for permanent level
	Autoload.player_level += int(xp_gained_this_run)
	Autoload.total_coins += Autoload.player_coins # Add current run coins to total permanent
	Autoload.total_gems += Autoload.player_gems # Add current run gems to total permanent
	Autoload.save_all_player_data() # Save all permanent data

	Autoload.reset_variables() # Reset run-specific variables for a new game
	reset_game() # Reset the game scene itself

	game_over_screen.hide()
	game_win_screen.hide() # Ensure win screen is hidden too

	var shop_scene = load("res://shop.tscn") # Load your shop scene
	get_tree().change_scene_to_packed(shop_scene)


func _on_revive_button_pressed() -> void:
	if Autoload.life_token > 0:
		Autoload.life_token -= 1
		Autoload.save_all_player_data() # Save token deduction immediately

		game_over_screen.hide()
		revive_countdown_timer.stop()

		var player_node = get_node("player")
		player_node.revive_player() # Player script handles health, position, etc.
		emit_signal("play_sfx", "revive") # Play revive sound

		get_tree().paused = false
		game_over = false # Reset game_over flag if revived
		print("Player revived with token.")
	else:
		print("ERROR: Revive button pressed with no tokens. This should have been disabled or hidden!")


func _on_return_to_main_menu_button_pressed() -> void: # Assuming a button on game over/win screen
	game_over_screen.hide()
	game_win_screen.hide()
	revive_countdown_timer.stop()
	finalize_game_over()


func assign_upgrades_to_buttons():
	# References to the actual buttons
	var upgrade_buttons_list = [upgrade_button1, upgrade_button2, upgrade_button3]
	var upgrade_labels_list = [upgrade_text1, upgrade_text2, upgrade_text3]
	var upgrade_descs_list = [upgrade_desc1, upgrade_desc2, upgrade_desc3]
	# References to the parent containers (Upgrade1, Upgrade2, etc.) for visibility/highlight
	var upgrade_containers_list = [
		%UpgradeMenu/Upgrade1,
		%UpgradeMenu/Upgrade2,
		%UpgradeMenu/Upgrade3
	]

	# Add 4th button/label/desc/container if it exists
	if upgrade_button4: # Check if the @onready var is not null
		upgrade_buttons_list.append(upgrade_button4)
		upgrade_labels_list.append(upgrade_text4)
		upgrade_descs_list.append(upgrade_desc4)
		upgrade_containers_list.append(%UpgradeMenu/Upgrade4)


	var count = upgrade_buttons_list.size()

	var upgrade_keys = all_upgrades.keys()
	upgrade_keys.shuffle()

	var filled = 0
	var i = 0
	var chosen_upgrade_types = []
	# Prioritize available upgrades and ensure uniqueness
	while filled < count and i < upgrade_keys.size():
		var upgrade_type = upgrade_keys[i]
		var level_in_type = upgrade_levels.get(upgrade_type, 0)
		var upgrade_data_list = all_upgrades[upgrade_type]

		if level_in_type < upgrade_data_list.size() and not chosen_upgrade_types.has(upgrade_type):
			var upgrade = upgrade_data_list[level_in_type]
			upgrade_buttons_list[filled].set_meta("upgrade_type", upgrade_type)
			upgrade_buttons_list[filled].set_meta("upgrade_level", level_in_type)
			upgrade_labels_list[filled].text = upgrade_type
			upgrade_descs_list[filled].text = upgrade["desc"]
			upgrade_containers_list[filled].visible = true # Make sure container is visible
			chosen_upgrade_types.append(upgrade_type) # Track chosen types to avoid duplicates
			filled += 1
		i += 1
	# If not enough unique upgrades, hide remaining buttons
	while filled < count:
		upgrade_containers_list[filled].visible = false
		filled += 1


func apply_upgrade(button):
	var type = button.get_meta("upgrade_type")
	if type == "None": # Handle no upgrade option (if you implement one)
		print("No upgrade selected.")
	else:
		var level_applied = button.get_meta("upgrade_level")

		var upgrade = all_upgrades[type][level_applied]
		if "apply" in upgrade and upgrade["apply"] is Callable:
			upgrade["apply"].call()
			emit_signal("play_sfx", "upgrade_apply") # Play upgrade apply sound
		else:
			push_error("Missing or invalid 'apply' for upgrade: %s" % type)

		upgrade_levels[type] = upgrade_levels.get(type, 0) + 1

	upgrade_menu.hide()
	%"Level-up-fx".hide()
	get_tree().paused = false # Unpause the game after applying upgrade and hiding menu
	player.set_physics_process(true) # Resume player movement
	#player.visible = true # Make player visible again


func _on_upgrade_button_1_pressed() -> void:
	apply_upgrade(upgrade_button1)

func _on_upgrade_button_2_pressed() -> void:
	apply_upgrade(upgrade_button2)

func _on_upgrade_button_3_pressed() -> void:
	apply_upgrade(upgrade_button3)

func _on_upgrade_button_4_pressed() -> void:
	apply_upgrade(upgrade_button4)


func reset_game():
	print("TRACE (Gameplay): Resetting game state.")
	time_passed = 0.0
	game_over = false
	get_tree().paused = false

	game_timer_label.text = "00:00"
	score_label.text = "Level 1"
	coins_label.text = str(Autoload.player_coins)
	gems_label.text = str(Autoload.player_gems) # Reset displayed gems
	level_progress_bar.value = 0
	level = 1 # Reset the in-game level counter

	var player_node = get_node("player")
	if player_node:
		player_node._update_stats() # Assuming this resets player stats
		player_node.health = player_node.max_health
		player_node.velocity = Vector2.ZERO
		player_node.global_position = Vector2(300, 300) # Or your starting player position
		player_node.get_node("%ProgressBar").value = player_node.max_health
		player_node.set_physics_process(true)
		player_node.visible = true

	upgrade_menu.hide()
	game_over_screen.hide()
	pause_menu.hide()
	game_win_screen.hide() # Ensure win screen is hidden on reset
	%"Level-up-fx".hide() # Hide level up FX on reset

	# Clear all existing mobs and drops from the scene
	for mob in get_tree().get_nodes_in_group("enemies"): # Assuming all enemies are in "enemies" group
		if mob.has_method("reset") and mob.has_method("get_pool_group_name"):
			PoolManager.return_to_pool(mob.get_pool_group_name(), mob)
		else:
			mob.queue_free()

	for drop in get_tree().get_nodes_in_group("drops"): # Assuming your drops are in this group
		drop.queue_free()

	# Reset guns to initial state (only Rifle active)
	for gun in get_tree().get_nodes_in_group("guns"):
		if gun.name == "Rifle": # Adjust if your starting gun has a different name
			gun.show()
			gun.set_process_mode(Node.PROCESS_MODE_INHERIT)
		else:
			gun.hide()
			gun.set_process_mode(Node.PROCESS_MODE_DISABLED)

	mob_spawn_timer.start() # Restart original mob spawner
	# Reset and restart dynamic enemy spawning timers
	current_enemy_type_index = 0
	current_boss_type_index = 0
	_select_next_enemy_type() # Re-select initial enemy type
	enemy_type_change_timer.start()
	boss_spawn_timer.start()


func _on_pause_button_pressed() -> void:
	get_tree().paused = true
	pause_menu.show()
	emit_signal("play_sfx", "ui_pause") # Play pause sound

	if game_music_player and game_music_player.playing:
		game_music_player.stop()
	if pause_menu_music_player:
		pause_menu_music_player.play()

	if player_animations:
		player_animations.play("Idle") # Assuming "Idle" is your default idle animation
		player_animations.stop() # Stop all player animations when paused
	
	player.set_physics_process(false) # Stop player movement/physics when paused


func _on_resume_button_pressed() -> void:
	get_tree().paused = false
	pause_menu.hide()
	emit_signal("play_sfx", "ui_resume") # Play resume sound

	if pause_menu_music_player and pause_menu_music_player.playing:
		pause_menu_music_player.stop()
	if game_music_player:
		game_music_player.play()

	if player_animations:
		# Resume appropriate player animation based on player's state (e.g., movement)
		# For simplicity, you might just play "Idle" or a "Run" if the player was moving.
		# A more robust solution would be to save the last played animation state.
		player_animations.play("Run") # Or whatever is appropriate for resuming gameplay
	
	player.set_physics_process(true) # Resume player movement/physics



func _on_player_revived() -> void:
	# This function is called by the player script after reviving
	game_over_screen.hide()
	revive_countdown_timer.stop()

	get_tree().paused = false
	game_over = false # Reset game_over flag if revived
	
	emit_signal("play_sfx", "revive") # Play revive sound

	if player_animations:
		player_animations.play("Idle") # Set player back to idle or a running animation
		player.set_physics_process(true) # Re-enable player movement
	print("Player revived with token.")



func _on_revive_countdown_timer_timeout() -> void:
	print("TRACE (Gameplay): Revive countdown timed out. No revival.")
	finalize_game_over()


func _on_game_duration_end():
	# This function is called when the game duration (10 minutes) ends.
	# The _process function already handles pausing and showing the win screen.
	# This acts as a callback for any other specific logic you want when time runs out.
	print("Game Duration Ended! Player survived for 10 minutes.")
