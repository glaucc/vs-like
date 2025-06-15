extends Node2D

@onready var game_over_screen = %GameOver
@onready var revive_button = %ReviveButton
@onready var revive_timer_label = %ReviveTimerLabel
@onready var revive_countdown_timer = %ReviveCountdownTimer

var shake_strength:float = 0.0

var pause_menu_opened = Autoload.pause_menu_opened

@onready var difficulty_scaler_timer = %DifficultyScalerTimer # New Timer node
var base_mob_spawn_rate: float = 0.7 # Starting spawn rate
var min_mob_spawn_rate: float = 0.1 # Fastest spawn rate
var spawn_rate_decrease_amount: float = 0.05 # How much to decrease each time the scaler times out
var spawn_rate_scaling_interval: float = 10.0 # How often (seconds) to decrease spawn rate

var regular_mob_spawn_frequency: float = 0.7 # Initial frequency for regular mobs

var time_passed: float = 0.0
var game_over: bool = false
var end_time: float = 0.0 # This variable is mostly superseded by game_duration
var game_duration: float = 600.0 # 10 minutes (600 seconds)


@onready var game_music_player = %GameMusicPlayer # Your main game music player
@onready var game_music1
@onready var first_music_played:bool = true
@onready var pause_menu_music_player = %PauseMenuMusicPlayer

@onready var player_animations: AnimationPlayer = %player_animations

@onready var game_timer_label = %Time # Assuming your game time display is named 'Time'
@onready var player: CharacterBody2D = $player # Ensure this path is correct

@onready var upgrade_menu = %UpgradeMenu # Correct: Matches image
# Corrected paths for upgrade buttons and their labels/descriptions based on image
@onready var upgrade_button1 = %UpgradeButton1
@onready var upgrade_button2 = %UpgradeButton2
@onready var upgrade_button3 = %UpgradeButton3

@onready var upgrade_text1 = %Upgrade1text
@onready var upgrade_text2 = %Upgrade2text
@onready var upgrade_text3 = %Upgrade3text

@onready var upgrade_desc1 = %UpgradeDesc1
@onready var upgrade_desc2 = %UpgradeDesc2
@onready var upgrade_desc3 = %UpgradeDesc3

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
const REGULAR_ENEMY_TYPES = ["mob", "bat", "python", "psycho", "man_eating_flower", "pumpking", "ghost", "small_worm", "big_worm", "slime"] # Ensure these match your Pool_manager.gd
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

var enemy_phase_counter: int = 0 # ADD THIS LINE

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


const all_upgrades = {
	# --- Player Upgrades ---
	"Max Health": [
		{"desc": "Max Health: +10%", "value": 1.1, "type": "Player_MaxHealth_Multiplier"},
		{"desc": "Max Health: +10%", "value": 1.1, "type": "Player_MaxHealth_Multiplier"},
		{"desc": "Max Health: +10%", "value": 1.1, "type": "Player_MaxHealth_Multiplier"},
		{"desc": "Max Health: +10%", "value": 1.1, "type": "Player_MaxHealth_Multiplier"},
		{"desc": "Max Health: +10%", "value": 1.1, "type": "Player_MaxHealth_Multiplier"},
	],
	"Movement Speed": [
		{"desc": "Movement Speed: +10%", "value": 1.1, "type": "Player_Speed_Multiplier"},
		{"desc": "Movement Speed: +10%", "value": 1.1, "type": "Player_Speed_Multiplier"},
		{"desc": "Movement Speed: +10%", "value": 1.1, "type": "Player_Speed_Multiplier"},
		{"desc": "Movement Speed: +10%", "value": 1.1, "type": "Player_Speed_Multiplier"},
		{"desc": "Movement Speed: +10%", "value": 1.1, "type": "Player_Speed_Multiplier"},
	],
	#"Damage Bonus": [
		#{"desc": "Damage Bonus: +10%", "value": 1.1, "type": "Player_Damage_Multiplier"},
		#{"desc": "Damage Bonus: +10%", "value": 1.1, "type": "Player_Damage_Multiplier"},
		#{"desc": "Damage Bonus: +10%", "value": 1.1, "type": "Player_Damage_Multiplier"},
		#{"desc": "Damage Bonus: +10%", "value": 1.1, "type": "Player_Damage_Multiplier"},
		#{"desc": "Damage Bonus: +10%", "value": 1.1, "type": "Player_Damage_Multiplier"},
	#],
	"Crit Chance": [
		{"desc": "Crit Chance: +5%", "value": 0.05, "type": "Player_CritChance_Addition"},
		{"desc": "Crit Chance: +5%", "value": 0.05, "type": "Player_CritChance_Addition"},
		{"desc": "Crit Chance: +5%", "value": 0.05, "type": "Player_CritChance_Addition"},
		{"desc": "Crit Chance: +5%", "value": 0.05, "type": "Player_CritChance_Addition"},
		{"desc": "Crit Chance: +5%", "value": 0.05, "type": "Player_CritChance_Addition"},
	],
	#"Crit Damage": [
		#{"desc": "Crit Damage: +25%", "value": 0.25, "type": "Player_CritDamage_Addition"},
		#{"desc": "Crit Damage: +25%", "value": 0.25, "type": "Player_CritDamage_Addition"},
		#{"desc": "Crit Damage: +25%", "value": 0.25, "type": "Player_CritDamage_Addition"},
		#{"desc": "Crit Damage: +25%", "value": 0.25, "type": "Player_CritDamage_Addition"},
		#{"desc": "Crit Damage: +25%", "value": 0.25, "type": "Player_CritDamage_Addition"},
	#],
	#"Pickup Range": [
		#{"desc": "Pickup Range: +25%", "value": 1.25, "type": "Player_PickupRange_Multiplier"},
		#{"desc": "Pickup Range: +25%", "value": 1.25, "type": "Player_PickupRange_Multiplier"},
		#{"desc": "Pickup Range: +25%", "value": 1.25, "type": "Player_PickupRange_Multiplier"},
		#{"desc": "Pickup Range: +25%", "value": 1.25, "type": "Player_PickupRange_Multiplier"},
		#{"desc": "Pickup Range: +25%", "value": 1.25, "type": "Player_PickupRange_Multiplier"},
	#],
	#"Life Tokens": [
		#{"desc": "Life Token: +1", "value": 1, "type": "Player_LifeToken_Add"},
	#],

	## --- Gun Upgrades (General) ---
	#"Projectile Speed": [
		#{"desc": "Projectile Speed: +10%", "value": 1.1, "type": "Projectile_Speed_Multiplier"},
		#{"desc": "Projectile Speed: +10%", "value": 1.1, "type": "Projectile_Speed_Multiplier"},
		#{"desc": "Projectile Speed: +10%", "value": 1.1, "type": "Projectile_Speed_Multiplier"},
		#{"desc": "Projectile Speed: +10%", "value": 1.1, "type": "Projectile_Speed_Multiplier"},
		#{"desc": "Projectile Speed: +10%", "value": 1.1, "type": "Projectile_Speed_Multiplier"},
	#],
	"Attack Speed": [
		{"desc": "Attack Speed: +10%", "value": 1.1, "type": "Attack_Speed_Multiplier"},
		{"desc": "Attack Speed: +10%", "value": 1.1, "type": "Attack_Speed_Multiplier"},
		{"desc": "Attack Speed: +10%", "value": 1.1, "type": "Attack_Speed_Multiplier"},
		{"desc": "Attack Speed: +10%", "value": 1.1, "type": "Attack_Speed_Multiplier"},
		{"desc": "Attack Speed: +10%", "value": 1.1, "type": "Attack_Speed_Multiplier"},
	],
	#"Projectile Damage": [
		#{"desc": "Projectile Damage: +10%", "value": 1.1, "type": "Projectile_Damage_Multiplier"},
		#{"desc": "Projectile Damage: +10%", "value": 1.1, "type": "Projectile_Damage_Multiplier"},
		#{"desc": "Projectile Damage: +10%", "value": 1.1, "type": "Projectile_Damage_Multiplier"},
		#{"desc": "Projectile Damage: +10%", "value": 1.1, "type": "Projectile_Damage_Multiplier"},
		#{"desc": "Projectile Damage: +10%", "value": 1.1, "type": "Projectile_Damage_Multiplier"},
	#],
	#"Projectile Amount": [
		#{"desc": "Projectile Amount: +1", "value": 1, "type": "Projectile_Amount_Add"},
		#{"desc": "Projectile Amount: +1", "value": 1, "type": "Projectile_Amount_Add"},
		#{"desc": "Projectile Amount: +1", "value": 1, "type": "Projectile_Amount_Add"},
		#{"desc": "Projectile Amount: +1", "value": 1, "type": "Projectile_Amount_Add"},
		#{"desc": "Projectile Amount: +1", "value": 1, "type": "Projectile_Amount_Add"},
	#],

	# --- Specific Gun Upgrades ---
	"Rifle": [
		{"desc": "Rifle (New)", "activate_gun": true, "type": "Rifle"},
		{"desc": "Rifle: +1 Bullet", "value": 1, "type": "Rifle_Amount"},
		{"desc": "Rifle: +2 Damage", "value": 2, "type": "Rifle_Damage"},
		{"desc": "Rifle: -0.1s Cooldown", "value": 0.1, "type": "Rifle_Cooldown_Reduction"},
		{"desc": "Rifle: +100 Range", "value": 100, "type": "Rifle_Range"},
		{"desc": "Rifle: +50 Speed", "value": 50, "type": "Rifle_Speed"},
	],
	"Shotgun": [
		{"desc": "Shotgun (New)", "activate_gun": true, "type": "Shotgun"},
		{"desc": "Shotgun: +1 Projectile", "value": 1, "type": "Shotgun_Amount"},
		{"desc": "Shotgun: +3 Damage", "value": 3, "type": "Shotgun_Damage"},
		{"desc": "Shotgun: -0.2s Cooldown", "value": 0.2, "type": "Shotgun_Cooldown_Reduction"},
		{"desc": "Shotgun: +75 Range", "value": 75, "type": "Shotgun_Range"},
		{"desc": "Shotgun: +40 Speed", "value": 40, "type": "Shotgun_Speed"},
	],
	"Machine Gun": [ # Assuming node name is "machinegun"
		{"desc": "Machine Gun (New)", "activate_gun": true, "type": "Machine_Gun"},
		{"desc": "Machine Gun: +0.2 Fire Rate", "value": 0.2, "type": "Machine_Gun_FireRate"}, # Increase rate (smaller cooldown)
		{"desc": "Machine Gun: +1 Damage", "value": 1, "type": "Machine_Gun_Damage"},
		{"desc": "Machine Gun: -0.05s Cooldown", "value": 0.05, "type": "Machine_Gun_Cooldown_Reduction"},
		{"desc": "Machine Gun: +50 Range", "value": 50, "type": "Machine_Gun_Range"},
		{"desc": "Machine Gun: +30 Speed", "value": 30, "type": "Machine_Gun_Speed"},
	],
	"Laser": [
		{"desc": "Laser (New)", "activate_gun": true, "type": "Laser"},
		{"desc": "Laser: +1 Tick Damage", "value": 1, "type": "Laser_Damage"},
		{"desc": "Laser: -0.1s Beam Interval", "value": 0.1, "type": "Laser_Interval_Reduction"},
		{"desc": "Laser: +100 Range", "value": 100, "type": "Laser_Range"},
		{"desc": "Laser: +1 Beam Amount", "value": 1, "type": "Laser_Amount"},
		{"desc": "Laser: Wider Beam", "value": 1.2, "type": "Laser_Width_Multiplier"}, # Increase by 20%
	],
	"Rocket": [
		{"desc": "Rocket (New)", "activate_gun": true, "type": "Rocket"},
		{"desc": "Rocket: +5 Damage", "value": 5, "type": "Rocket_Damage"},
		{"desc": "Rocket: -0.3s Cooldown", "value": 0.3, "type": "Rocket_Cooldown_Reduction"},
		{"desc": "Rocket: +1 Rocket", "value": 1, "type": "Rocket_Amount"},
		{"desc": "Rocket: +100 Explosion Radius", "value": 100, "type": "Rocket_Explosion_Radius"},
		{"desc": "Rocket: +50 Speed", "value": 50, "type": "Rocket_Speed"},
	],
	"Flamethrower": [ # Changed from "Gun 6"
		{"desc": "Flamethrower (New)", "activate_gun": true, "type": "Flamethrower"},
		{"desc": "Flamethrower: Both Sides", "value": Autoload.FireMode.BOTH_SIDES, "type": "Flamethrower_FireMode"},
		{"desc": "Flamethrower: Shorter Reload", "value": 0.3, "type": "Flamethrower_Reload_Reduction"}, # Reduce by 0.3 seconds
		{"desc": "Flamethrower: Four Sides", "value": Autoload.FireMode.FOUR_SIDES, "type": "Flamethrower_FireMode"},
		{"desc": "Flamethrower: +20 Damage", "value": 20, "type": "Flamethrower_Damage"},
		{"desc": "Flamethrower: +100 Range", "value": 100, "type": "Flamethrower_Range"}, # This would likely affect projectile lifetime or maximum distance
		{"desc": "Flamethrower: +50 Speed", "value": 50, "type": "Flamethrower_Speed"},
	],
	"Shockwave": [
		{"desc": "Shockwave (New)", "activate_gun": true, "type": "Shockwave"},
		{"desc": "+1 Shockwave", "value": 1, "type": "Shockwave_Amount"},
		{"desc": "-1s Cooldown (Shockwave)", "value": 1.0, "type": "Shockwave_Cooldown_Reduction"},
		{"desc": "+10 Damage (Shockwave)", "value": 10, "type": "Shockwave_Damage"},
		{"desc": "+50 Radius (Shockwave)", "value": 50, "type": "Shockwave_Radius"},
		{"desc": "+0.1 Scale Speed (Shockwave)", "value": 0.1, "type": "Shockwave_Scale_Speed"}, # How fast it grows
	],
}

var upgrade_levels = {
	#Passives
	"Damage": 0,
	"Attack Speed": 0,
	"Movement Speed": 0,
	"Crit Chance": 0,
	"Bullet Size": 0,
	"Max Health": 0,
	"Luck": 0,
	"Health Regen": 0,
	#"Pickup Range": 0,
	#"Life Tokens": 0,
	#"Projectile Speed": 0,
	#"Projectile Damage": 0,
	#"Projectile Amount": 0,
	
	
	#Active guns (initial level 0 for inactive, 1+ for upgrades)
	"Rifle": 0,
	"Shotgun": 2,
	"Machine Gun": 0,
	"Laser": 0,
	"Rocket": 1,
	"Flamethrower": 0, # Set to 0 if not starting unlocked
	"Shockwave": 0,
	
	# Evo (example placeholders)
	"Anti-Gravity Gun": 0,
	"Water Vortex": 0,
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
	print("GameMusicPlayer: ", %GameMusicPlayer.get_stream())
	randomize()
	
	
	game_music1 = %GameMusicPlayer.get_stream()

	# --- MODIFIED: Applying Initial Gun States based on upgrade_levels ---
	var guns_to_activate = ["Rifle", "Shotgun", "Machine Gun", "Laser", "Rocket", "Flamethrower", "Shockwave"]
	for gun_name in guns_to_activate:
		var desired_level = upgrade_levels.get(gun_name, 0)
		if desired_level > 0:
			var autoload_active_flag_name = gun_name.replace(" ", "").to_lower() + "_active"
			Autoload.set(autoload_active_flag_name, true)
			var upgrade_data_index = desired_level - 1
			if gun_name in all_upgrades and all_upgrades[gun_name].size() > upgrade_data_index:
				var initial_upgrade_data = all_upgrades[gun_name][upgrade_data_index]
				Autoload.apply_gameplay_upgrade(initial_upgrade_data.type, initial_upgrade_data)
				upgrade_levels[gun_name] = desired_level
				print("DEBUG: Forced", gun_name, "active at Level", desired_level, ". Autoload active flag set.")
			else:
				print("WARNING: Could not apply initial upgrade for", gun_name, "at Level", desired_level, ". Check 'all_upgrades' data.")
		else:
			var autoload_active_flag_name = gun_name.replace(" ", "").to_lower() + "_active"
			Autoload.set(autoload_active_flag_name, false)
	print("DEBUG: --- Finished Applying Initial Gun States ---")

	upgrade_menu.hide()
	game_over_screen.hide()
	pause_menu.hide()
	game_win_screen.hide()
	%"Level-up-fx".hide()

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
		print("DEBUG: Player signals connected.") # ADD THIS DEBUG LINE
	else:
		print("ERROR: Player node NOT found at '$player' in _ready()! Check path.") # ADD THIS DEBUG LINE

	if camera_2d and camera_2d.has_method("start_shake"):
		screen_shake_requested.connect(Callable(camera_2d, "start_shake"))
	if sfx_player:
		play_sfx.connect(Callable(self, "_on_play_sfx_requested"))
	sfx_player.set_process_mode(Node.PROCESS_MODE_ALWAYS)

	print("DEBUG: --- Initializing Gun Nodes from Autoload Flags ---")
	for gun_node in get_tree().get_nodes_in_group("guns"):
		var gun_name = gun_node.name
		var should_be_active = false
		match gun_name:
			"gun": should_be_active = Autoload.rifle_active
			"shotgun": should_be_active = Autoload.shotgun_active
			"machinegun": should_be_active = Autoload.machinegun_active
			"laser": should_be_active = Autoload.laser_active
			"rocket": should_be_active = Autoload.rocket_active
			"flamethrower": should_be_active = Autoload.flamethrower_active
			"shockwave": should_be_active = Autoload.shockwave_active
			_:
				should_be_active = false
				print("DEBUG: Unknown gun node encountered in _ready(): ", gun_name)
		print("DEBUG: Gun Node:", gun_name, "| Autoload Active State Checked (for node activation):", should_be_active)

		if should_be_active:
			gun_node.set_process_mode(Node.PROCESS_MODE_INHERIT)
			gun_node.show()
			if gun_node.has_method("_update_stats_from_autoload"):
				gun_node._update_stats_from_autoload()
				print("DEBUG: Called _update_stats_from_autoload for gun node:", gun_name)
		else:
			gun_node.set_process_mode(Node.PROCESS_MODE_DISABLED)
			gun_node.hide()
	print("DEBUG: --- Finished Initializing Gun Nodes from Autoload Flags ---")

	revive_countdown_timer.timeout.connect(Callable(self, "_on_revive_countdown_timer_timeout"))
	revive_button.pressed.connect(Callable(self, "_on_revive_button_pressed"))

	revive_countdown_timer.set_process_mode(Node.PROCESS_MODE_ALWAYS)
	game_over_screen.set_process_mode(Node.PROCESS_MODE_ALWAYS)
	revive_timer_label.set_process_mode(Node.PROCESS_MODE_ALWAYS)
	revive_button.set_process_mode(Node.PROCESS_MODE_ALWAYS)
	pause_menu.set_process_mode(Node.PROCESS_MODE_ALWAYS)

	# --- START OF CORRECTED ENEMY SPAWNING / DIFFICULTY SETUP ---
	# Apply initial passive upgrades (Do this once, typically after player setup)
	_apply_initial_passive_upgrades()
	print("DEBUG: Applied initial passive upgrades.") # ADD THIS DEBUG LINE
	# The debug prints for Autoload.flamethrower_active and Autoload.shotgun_active were duplicated
	# at the end of the file. They can stay here, but ensure they reflect the correct state.
	print("DEBUG: Autoload.flamethrower_active at end of _ready():", Autoload.flamethrower_active)
	print("DEBUG: Autoload.shotgun_active at end of _ready():", Autoload.shotgun_active)

	# Configure and start the regular mob spawn timer (SPAWNS FROM START)
	mob_spawn_timer.one_shot = false
	mob_spawn_timer.wait_time = regular_mob_spawn_frequency # Use initial frequency
	mob_spawn_timer.timeout.connect(Callable(self, "_on_mob_spawn_timer_timeout")) # ENSURE THIS IS CONNECTED
	mob_spawn_timer.start()
	print("DEBUG: mob_spawn_timer started immediately with wait_time: ", mob_spawn_timer.wait_time) # ADD THIS DEBUG LINE

	# Configure and start difficulty scaler (SPAWNS FROM START)
	difficulty_scaler_timer.wait_time = spawn_rate_scaling_interval
	difficulty_scaler_timer.one_shot = false # Make it loop
	difficulty_scaler_timer.timeout.connect(Callable(self, "_on_difficulty_scaler_timeout"))
	difficulty_scaler_timer.start()
	print("DEBUG: difficulty_scaler_timer started.") # ADD THIS DEBUG LINE

	# Configure and start the ENEMY PHASE / WAVE CHANGE TIMER (triggers every minute)
	enemy_type_change_timer.wait_time = 60.0 # Trigger every 1 minute
	enemy_type_change_timer.one_shot = false # Make it loop
	enemy_type_change_timer.timeout.connect(Callable(self, "_on_enemy_type_change_timer_timeout")) # ENSURE THIS IS CONNECTED
	enemy_type_change_timer.start()
	print("DEBUG: enemy_type_change_timer (phase timer) started with wait_time: ", enemy_type_change_timer.wait_time) # ADD THIS DEBUG LINE

	# Connect boss spawn timer (if you want independent boss spawns)
	# If boss spawns are *only* handled by enemy_type_change_timer, you can remove this.
	# If you keep it, make sure its wait_time is set in the inspector or here.
	# boss_spawn_timer.timeout.connect(Callable(self, "_on_boss_spawn_timer_timeout"))
	# boss_spawn_timer.start()
	# print("DEBUG: boss_spawn_timer started.") # ADD THIS DEBUG LINE

	# --- END OF CORRECTED ENEMY SPAWNING / DIFFICULTY SETUP ---

	# Connect upgrade buttons
	upgrade_button1.pressed.connect(Callable(self, "_on_upgrade_button_1_pressed"))
	upgrade_button2.pressed.connect(Callable(self, "_on_upgrade_button_2_pressed"))
	upgrade_button3.pressed.connect(Callable(self, "_on_upgrade_button_3_pressed"))

	# Connect pause and resume buttons
	pause_button.pressed.connect(Callable(self, "_on_pause_button_pressed"))
	resume_button.pressed.connect(Callable(self, "_on_resume_button_pressed"))

	# Initialize dynamic enemy spawning (initial enemy type)
	_select_next_enemy_type() # This just sets the initial type, not starts a timer
	print("DEBUG: Initial enemy type selected: ", REGULAR_ENEMY_TYPES[current_enemy_type_index]) # ADD THIS DEBUG LINE

	# REMOVE THESE 4 LINES (they were part of the old 'no enemies for 1 min' logic and duplicated)
	# Initially stop the mob_spawn_timer; it will be started after the delay
	# mob_spawn_timer.stop()
	# DEBUG: Confirm mob spawn timer is stopped initially
	# print("DEBUG: mob_spawn_timer initially stopped.")




func _apply_initial_passive_upgrades():
	# This function should be called once at _ready() to apply passive stats
	# that are not tied to specific gun nodes, based on Autoload's state.
	# This assumes Autoload holds the current levels of these passives.
	
	# You would typically have a function in Autoload (or in player)
	# that recalculates player stats based on these levels.
	if player:
		player._update_stats() # This function should read from Autoload and apply

	# For any passive abilities that activate a "node" (like a health regen node
	# or a magnet node), you would activate them here based on their levels.
	# Example:
	# if Autoload.health_regen > 0: # Check if health regen has been upgraded
	#     var health_regen_node = %HealthRegenNode # Assuming such a node exists
	#     if health_regen_node:
	#         health_regen_node.set_process(true)
	#         health_regen_node.show()
	pass # Placeholder, implement as needed.



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


# These individual gun activation functions are largely superseded by Autoload.apply_gameplay_upgrade
# and the _ready() logic that checks Autoload flags. They can be removed if all gun activation
# is handled by Autoload and the gun nodes themselves.
# func gun1_activate():
#     for gun in get_tree().get_nodes_in_group("guns"):
#         if gun.name == "gun":
#             gun.set_process_mode(Node.PROCESS_MODE_INHERIT);
#             gun.show()

# func gun2_activate():
#     %gun2.set_process_mode(Node.PROCESS_MODE_INHERIT);
#     %gun2.show()

# func gun3_activate():
#     %gun3.set_process_mode(Node.PROCESS_MODE_INHERIT);
#     %gun3.show()

# func gun4_activate():
#     %gun4.set_process_mode(Node.PROCESS_MODE_INHERIT);
#     %gun4.show()

# func gun5_activate():
#     %gun5.set_process_mode(Node.PROCESS_MODE_INHERIT);
#     %gun5.show()

# func gun6_activate():
#     %gun6.set_process_mode(Node.PROCESS_MODE_INHERIT);
#     %gun6.show()


func apply_health_upgrade():
	if player: # Ensure player exists
		player.max_health = int(player.max_health * Autoload.player_health_percent) # Use Autoload's multiplier
		player.health = player.max_health
		player.get_node("%ProgressBar").max_value = player.max_health
		player.get_node("%ProgressBar").value = player.health
		emit_signal("play_sfx", "upgrade_health") # Play health upgrade sound


func handle_upgrade_input():
	var max_selection = 3


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



func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("esc") and !get_tree().paused and !pause_menu_opened:
			emit_signal("play_sfx", "ui_pause") # Play pause sound
	
	elif get_tree().paused:
		if Input.is_action_just_pressed("esc") and get_tree().paused and pause_menu_opened:
			emit_signal("play_sfx", "ui_resume") # Play resume sound


func _physics_process(delta: float) -> void:
	if not get_tree().paused:
		Autoload.level = level
		var score = Autoload.score
		level_progress_bar.value = score - required_xp[level - 1]
		level_progress_bar.max_value = required_xp[level] - required_xp[level - 1]
		score_label.text = "Level " + str(level)

		if level < required_xp.size() and score >= required_xp[level]:
			current_selection = 0
			if player:
				player.set_physics_process(false)
			upgrade_menu.show()
			upgrade_button1.grab_focus()
			assign_upgrades_to_buttons()
			menu_animations.play("show_menu")
			emit_signal("play_sfx", "level_up")
			if player:
				player._update_stats() # Update player stats after level up
			get_tree().paused = true
			level += 1
			%"Level-up-fx".show()
			if level_up_fx.has_method("play"):
				%"Level-up-fx".show()
				level_up_fx.play("upgrade_idle")
	
		


# --- NEW: Dynamic Enemy Spawning Functions ---
func _select_next_enemy_type():
	current_enemy_type_index = (current_enemy_type_index + 1) % REGULAR_ENEMY_TYPES.size()
	var selected_type = REGULAR_ENEMY_TYPES[current_enemy_type_index]
	# print("DEBUG: Next regular enemy type: ", selected_type)

func _select_next_boss_type():
	current_boss_type_index = (current_boss_type_index + 1) % BOSS_ENEMY_TYPES.size()
	var selected_type = BOSS_ENEMY_TYPES[current_boss_type_index]
	# print("DEBUG: Next boss type: ", selected_type)


func _on_enemy_type_change_timer_timeout():
	# This timer now acts as the 'phase' progression timer, firing every minute.
	enemy_phase_counter += 1
	print("DEBUG: Enemy phase change initiated. Current phase: ", enemy_phase_counter)

	# Always select the next regular enemy type for this phase
	_select_next_enemy_type()
	print("DEBUG: Regular enemy type changed to: ", REGULAR_ENEMY_TYPES[current_enemy_type_index])

	# Example: Spawn a boss every 3rd minute (adjust '3' as desired)
	if enemy_phase_counter % 3 == 0:
		print("DEBUG: Boss spawn triggered for phase: ", enemy_phase_counter)
		_select_next_boss_type()
		spawn_mob(BOSS_ENEMY_TYPES[current_boss_type_index])
		emit_signal("play_sfx", "boss_spawn")




func spawn_mob(group_name: String) -> void:
	print("DEBUG: spawn_mob called for group: ", group_name) # ADD THIS LINE
	var new_mob = PoolManager.get_from_pool(group_name)
	if not new_mob:
		print("WARNING: PoolManager returned NULL for group: ", group_name, ". Is PoolManager correctly set up with this group?") # ADD THIS LINE
		return
	else:
		print("DEBUG: Successfully retrieved mob '", new_mob.name, "' from pool for group: ", group_name) # ADD THIS LINE

	# Check if path_follow_2d is valid and has a path set
	if not path_follow_2d:
		print("ERROR: path_follow_2d is not assigned or is null. Cannot spawn mob.") # ADD THIS LINE
		return
	if not path_follow_2d.get_parent() is Path2D:
		print("ERROR: path_follow_2d's parent is not a Path2D. Cannot spawn mob.") # ADD THIS LINE
		return

	path_follow_2d.progress_ratio = randf() # Assuming you use a Path2D for spawning
	new_mob.global_position = path_follow_2d.global_position
	add_child(new_mob)
	print("DEBUG: Mob '", new_mob.name, "' added to scene at position: ", new_mob.global_position) # ADD THIS LINE

	if new_mob.has_method("reset"):
		new_mob.reset(group_name)
	if new_mob.has_method("set_pool_group_name"):
		new_mob.set_pool_group_name(group_name)



func _on_mob_spawn_timer_timeout() -> void:
	# Mobs now spawn continuously from the start
	spawn_mob(REGULAR_ENEMY_TYPES[current_enemy_type_index])
	print("DEBUG: _on_mob_spawn_timer_timeout called. Spawning mob of type: ", REGULAR_ENEMY_TYPES[current_enemy_type_index], " at time: ", time_passed) # ADD time_passed



# --- NEW: Game Juice Functions ---
func _on_player_hit():
	print("DEBUG Gameplay: Player hit signal received in Gameplay. Triggering screen shake and sfx.") # ADD THIS DEBUG LINE
	emit_signal("screen_shake_requested", shake_strength, 0.1) # Trigger a short shake
	emit_signal("play_sfx", "player_hit") # Play player hit sound
	# Add any other visual feedback here, like player flashing red if not handled in Player.gd


# Connects to player.gem_collected signal
func _on_player_gem_collected(amount: int):
	Autoload.add_gems(amount) # Call Autoload's function to update current run's gems
	# SFX already emitted by _on_play_sfx_requested when gem_collect is emitted.
	#pass     


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
		# else:
		#     push_error("Could not load audio stream from ",sfx_path)
	# else:
	#     # This could happen if SFXPlayer is null or sfx_name is not matched
	#     print("WARNING: No SFX path for ... or SFXPlayer not available: ",sfx_name)


# --- Gun Activation Functions (adapted to new names) ---
# These functions should now be directly interacting with Autoload's `apply_gameplay_upgrade`
# and the Autoload.gun_active flags.
# The structure of `all_upgrades` should call Autoload's central function.
# Here's how you'd structure them if they still exist for some reason, but typically
# you'd pass the gun name and `activate_gun: true` to Autoload.apply_gameplay_upgrade.

# Removed direct activation here as Autoload handles it.
# func rifle_activate(): # Changed from gun1_activate
#     # This logic is now handled by Autoload.apply_gameplay_upgrade("Rifle", {"activate_gun": true})
#     pass

# func shotgun_activate():
#     pass

# func machinegun_activate():
#     pass

# func laser_activate():
#     pass

# func rocket_activate():
#     pass

# func flamethrower_activate():
#     pass

# func shockwave_activate():
#     pass

# --- Corrected button pressed functions to call Autoload.apply_gameplay_upgrade ---
func _on_upgrade_button_1_pressed():
	_apply_upgrade(upgrade_button1)
	%"Level-up-fx".hide()

func _on_upgrade_button_2_pressed():
	_apply_upgrade(upgrade_button2)
	%"Level-up-fx".hide()

func _on_upgrade_button_3_pressed():
	_apply_upgrade(upgrade_button3)
	%"Level-up-fx".hide()



func _apply_upgrade(button: Button):
	var upgrade_type = button.get_meta("upgrade_type")
	var upgrade_level_chosen = button.get_meta("upgrade_level")

	if upgrade_type and upgrade_level_chosen != null:
		# Get the actual upgrade data from the all_upgrades dictionary
		var upgrade_data = all_upgrades[upgrade_type][upgrade_level_chosen]
		
		# Call Autoload's central function to apply the upgrade
		# Autoload will handle updating its internal variables (e.g., player_damage_percent)
		# and activating guns/applying specific gun upgrades if needed.
		Autoload.apply_gameplay_upgrade(upgrade_data.type, upgrade_data) # Use the "type" key for Autoload's match

		# Increment the upgrade level for this type
		upgrade_levels[upgrade_type] += 1
		
		
		
		# --- NEW CODE START ---
		# After an upgrade is applied (especially gun-related ones),
		# tell all active gun nodes to update their stats from Autoload.
		print("DEBUG: Calling _update_stats_from_autoload on all active guns after upgrade.")
		for gun_node in get_tree().get_nodes_in_group("guns"):
			# Only update if the gun node is active and has the method
			if gun_node.is_processing() and gun_node.has_method("_update_stats_from_autoload"):
				gun_node._update_stats_from_autoload()
		# --- NEW CODE END ---
		
		
		
		# Hide upgrade menu and resume game
		upgrade_menu.hide()
		menu_animations.play_backwards("show_menu") # Assuming an animation to hide
		get_tree().paused = false
		if player:
			player.set_physics_process(true) # Re-enable player physics
		emit_signal("play_sfx", "upgrade_apply") # Play upgrade apply sound

	# Else: This button was not properly assigned an upgrade, or an error occurred.
	# print("ERROR: Upgrade button pressed without valid upgrade data.")


func _on_player_health_depleted() -> void:
	# print("--- TRACE (Gameplay): _on_player_health_depleted() ENTRY ---")
	game_over_screen.show()
	# print("TRACE (Gameplay): After game_over_screen.show(), game_over_screen.is_visible() = ", game_over_screen.is_visible())

	end_time = time_passed # Store time of death
	game_over = true # Set game_over flag

	get_tree().paused = true # Pause the game
	# print("TRACE (Gameplay): After setting get_tree().paused = true, CURRENTLY it is: ", get_tree().paused)

	if player: # Ensure player exists before trying to access it
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
		# print("TRACE (Gameplay): Player health depleted. Showing revive option. Timer started.")
	else:
		revive_button.hide()
		revive_timer_label.show()
		revive_timer_label.text = "Game Over!" # Final text here
		revive_countdown_timer.stop()
		# print("TRACE (Gameplay): Player health depleted. No revive tokens. Displaying Game Over screen.")

	# print("--- TRACE (Gameplay): _on_player_health_depleted() EXIT ---")


func finalize_game_over() -> void:
	var xp_gained_this_run = Autoload.score / 10 # Example conversion for permanent level
	Autoload.player_level += int(xp_gained_this_run)
	Autoload.total_coins += Autoload.player_coins # Add current run coins to total permanent
	Autoload.total_gems += Autoload.player_gems # Add current run gems to total permanent
	Autoload.save_all_player_data() # Save all permanent data

	Autoload.reset_variables() # Reset run-specific variables for a new game
	# reset_game() # This function is not defined. If changing scene, it might not be needed.

	game_over_screen.hide()
	game_win_screen.show() # Ensure win screen is hidden too
	%GameMusicPlayer.stop()

	#var shop_scene = load("res://shop.tscn") # Load your shop scene
	#get_tree().change_scene_to_packed(shop_scene)


func _on_game_duration_end():
	# This is called when the game time runs out and player wins
	finalize_game_over() # Perform similar cleanup and save, then transition to shop/win screen


func _on_revive_button_pressed() -> void:
	if Autoload.life_token > 0:
		Autoload.life_token -= 1
		Autoload.save_all_player_data() # Save token deduction immediately

		game_over_screen.hide()
		revive_countdown_timer.stop()

		if player: # Ensure player exists
			player.revive_player() # Player script handles health, position, etc.
		emit_signal("play_sfx", "revive") # Play revive sound

		get_tree().paused = false
		game_over = false # Reset game_over flag if revived
		# print("Player revived with token.")
	# else:
	#     print("ERROR: Revive button pressed with no tokens. This should have been disabled or hidden!")


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




	var count = upgrade_buttons_list.size()

	var available_upgrade_types = []
	# Filter for upgrades that are not maxed out
	for upgrade_type in all_upgrades.keys():
		var current_level = upgrade_levels.get(upgrade_type, 0)
		if current_level < all_upgrades[upgrade_type].size():
			available_upgrade_types.append(upgrade_type)

	available_upgrade_types.shuffle() # Shuffle the available ones

	var filled_buttons = 0
	var chosen_upgrade_types = [] # To ensure unique upgrades on a single level-up screen

	# First, fill with truly "new" or unique upgrades if possible (e.g., activating a new gun)
	# This logic can be as simple or complex as you need. For now, we'll just try to pick unique ones
	# up to `count`.

	for upgrade_type in available_upgrade_types:
		if filled_buttons >= count:
			break # We've filled all our upgrade slots

		if not chosen_upgrade_types.has(upgrade_type):
			var current_level_for_type = upgrade_levels.get(upgrade_type, 0)
			var upgrade_data = all_upgrades[upgrade_type][current_level_for_type]

			# Assign to the next available button
			upgrade_buttons_list[filled_buttons].set_meta("upgrade_type", upgrade_type)
			upgrade_buttons_list[filled_buttons].set_meta("upgrade_level", current_level_for_type)
			upgrade_labels_list[filled_buttons].text = upgrade_type
			upgrade_descs_list[filled_buttons].text = upgrade_data.desc # Access directly
			upgrade_containers_list[filled_buttons].visible = true
			chosen_upgrade_types.append(upgrade_type)
			filled_buttons += 1
			
	# Hide any remaining unused buttons
	for i in range(filled_buttons, count):
		upgrade_containers_list[i].visible = false








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
		if gun.name == "shotgun": # Adjust if your starting gun has a different name
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
	pause_menu_opened = true
	Autoload.pause_menu_opened = pause_menu_opened
	get_tree().paused = true
	pause_menu.show()
	emit_signal("play_sfx", "ui_pause") # Play pause sound

	if game_music_player and game_music_player.playing and get_tree().paused:
		game_music_player.stop()
		print("stopped for pause")
	if pause_menu_music_player and get_tree().paused and pause_menu_opened:
		print("playing pause")
		pause_menu_music_player.play()


	if player_animations:
		player_animations.play("idle-down") # Assuming "Idle" is your default idle animation
		player_animations.stop() # Stop all player animations when paused
	
	player.set_physics_process(false) # Stop player movement/physics when paused


func _on_resume_button_pressed() -> void:
	pause_menu_opened = true
	Autoload.pause_menu_opened = pause_menu_opened
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
		player_animations.play("run-down") # Or whatever is appropriate for resuming gameplay
	
	player.set_physics_process(true) # Resume player movement/physics



func _on_player_revived() -> void:
	# This function is called by the player script after reviving
	game_over_screen.hide()
	revive_countdown_timer.stop()

	get_tree().paused = false
	game_over = false # Reset game_over flag if revived
	
	emit_signal("play_sfx", "revive") # Play revive sound

	if player_animations:
		player_animations.play("idle-down") # Set player back to idle or a running animation
		player.set_physics_process(true) # Re-enable player movement
	print("Player revived with token.")



func _on_revive_countdown_timer_timeout() -> void:
	print("TRACE (Gameplay): Revive countdown timed out. No revival.")
	finalize_game_over()


func _on_return_to_menu_button_pressed() -> void:
	var equipment_menu = load("res://game_menu.tscn")
	print("Loaded scene path:", equipment_menu.resource_path)
	get_tree().change_scene_to_packed(equipment_menu)


func _on_game_music_player_finished() -> void:
	first_music_played = !first_music_played
	print()
	var audio_stream
	
	if audio_stream == load("res://assets/music/full theme.mp3"):
		audio_stream = load("res://assets/music/LeftRightExcluded.mp3")
	elif audio_stream == load("res://assets/music/LeftRightExcluded.mp3"):
		audio_stream = load("res://assets/music/full theme.mp3")
	
	if !first_music_played:
		audio_stream = load("res://assets/music/full theme.mp3")
		%GameMusicPlayer.set_stream(audio_stream)
		
		
	elif first_music_played:
		audio_stream = load("res://assets/music/LeftRightExcluded.mp3")
		%GameMusicPlayer.set_stream(audio_stream)
