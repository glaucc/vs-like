extends Node

# --- Core Player Stats (These are usually reset per run or represent current run progress) ---
var player_coins: int = 0 # Coins collected during the current run
var player_gems: int = 0 # Gems collected during the current run, added to total_gems at end of run

# --- Player Permanent Data (to be saved/loaded) ---
var player_level: int = 1 # This is the permanent player account level (e.g., used for shop unlocks)
var total_coins: int = 0 # Total coins for shop/permanent purchases
var total_gems: int = 0 # Total gems for shop/premium currency (PERMANENT SAVE)
var life_token: int = 0 # Revive tokens (Permanent, deducts from this pool)

# --- Game State (Current run progress) ---
var score: int = 0 # XP collected during the current run
var level: int = 1 # Current in-game level (XP level)

# Mobs (This data should ideally be in a separate Autoload like 'MobData' if it's purely data)

@export var mob_stats: Dictionary = { # Added @export for editor visibility/modification
	"mob": {"base_health": 240, "base_speed": 100, "xp_value": 1, "coin_chance": 0.2},
	"bat": {"base_health": 260, "base_speed": 120, "xp_value": 1, "coin_chance": 0.15}, # Updated health
	"python": {"base_health": 290, "base_speed": 80, "xp_value": 2, "coin_chance": 0.3},
	"psycho": {"base_health": 350, "base_speed": 90, "xp_value": 3, "coin_chance": 0.25},
	"man_eating_flower": {"base_health": 250, "base_speed": 70, "xp_value": 5, "coin_chance": 0.2}, # Added, assuming speed/xp/coin
	"pumpking": {"base_health": 390, "base_speed": 60, "xp_value": 10, "coin_chance": 0.3}, # Added, assuming speed/xp/coin
	"ghost": {"base_health": 430, "base_speed": 110, "xp_value": 7, "coin_chance": 0.18}, # Added, assuming speed/xp/coin
	"small_worm": {"base_health": 510, "base_speed": 50, "xp_value": 4, "coin_chance": 0.22}, # Added, assuming speed/xp/coin
	"big_worm": {"base_health": 620, "base_speed": 40, "xp_value": 12, "coin_chance": 0.35}, # Added, assuming speed/xp/coin
	"slime": {"base_health": 800, "base_speed": 30, "xp_value": 15, "coin_chance": 0.4}, # Added, assuming speed/xp/coin
	"bull_boss": {"base_health": 5000, "base_speed": 70, "xp_value": 70, "coin_chance": 0.6}, # Updated health, added xp/coin
	"giant_boss": {"base_health": 8000, "base_speed": 50, "xp_value": 100, "coin_chance": 0.7}, # Updated health, added xp/coin
	"boss1": {"base_health": 12000, "base_speed": 60, "xp_value": 150, "coin_chance": 0.5}, # Updated health, added xp/coin
}

# --- Inventory and Equipment ---
var player_inventory: Dictionary = {}
var player_equipped_items: Dictionary = {
	"equip_slot_1": "",
	"equip_slot_2": "",
	"equip_slot_3": "",
	"equip_slot_4": "",
}

##-----------------------------------
## GUNS (Permanent Unlocks - Saved/Loaded)
##----------------------------------
# These flags indicate if a gun has been permanently unlocked by the player.
# They are NOT reset per run.

var rifle_active: bool = false # Start with rifle active if it's the default gun
var shotgun_active: bool = true # Retained original value, assuming it's a starting gun
var machinegun_active: bool = false
var laser_active: bool = false
var rocket_active: bool = false
var flamethrower_active: bool = false
var shockwave_active: bool = false

# Individual gun stats (these are also permanent and upgraded over time)
# Rifle/Pistol
var rifle_bullets: int = 1
var rifle_base_damage: int = 25 # Initialized rifle_base_damage
var rifle_attack_speed: float = 1.0

# Shotgun specific stats
var shotgun_base_damage: int = 39
var shotgun_magazine: int = 6 # This might be number of pellets per shot in some games, or bullets per magazine
var shotgun_spread_bullets: int = 5
var shotgun_cooldown: float = 0.3
var shotgun_reload_duration: float = 2.0
var shotgun_bullet_speed: int = 700
var shotgun_bullet_range: int = 500
var shotgun_bullets: int = 1 # Not clear if this is useful if shotgun_spread_bullets exists


# Machine Gun
var machinegun_bullets: int = 1 # Not typically used for continuous fire guns, more for burst size
var machinegun_base_damage: int = 22


# Laser
var laser_bullets: int = 1 # For laser, this might be a single beam, or number of concurrent beams
var laser_base_damage: int = 42 # Corrected typo: laset_base_damage -> laser_base_damage
var laser_damage_per_second : int = 120
var laser_duration : float = 2.0
var laser_cooldown : float = 5.0


# Rocket Launcher
var rocket_bullets: int = 1 # Number of rockets per shot, or rockets in magazine
var explosion_size: float = 100.0
var rocket_base_damage: int = 102

var rocket_magazine_size: int = 4   # How many rockets in a magazine
var rocket_reload_duration: float = 2.5 # How long it takes to reload rockets


# Flamethrower specific stats
var flamethrower_bullets: int = 1 # Not directly used by flamethrower (magazine based)
var flamethrower_base_damage: int = 52
var flamethrower_magazine_duration: float = 3.0 # seconds (This will be adjusted by sound length in flamethrower.gd)
var flamethrower_size: int = 1 # Not directly used in flamethrower.gd for size yet
var flamethrower_reload_duration: float = 4.0
var flamethrower_bullet_speed: int = 700
var flamethrower_bullet_range: int = 500


# NEW: Flamethrower Fire Modes (copied from flamethrower.gd for Autoload to manage)
enum FireMode { SINGLE_RIGHT, BOTH_SIDES, FOUR_SIDES }
# RENAMED THIS VARIABLE TO MATCH flamethrower.gd's EXPECTATION
var current_flamethrower_fire_mode: FireMode = FireMode.SINGLE_RIGHT
var current_flamethrower_sound_type: String = "short" # "short", "medium", "long"


# Shockwave
var shockwave_amount:int = 1
var shockwave_cooldown: float = 5.0
var shockwave_base_damage: int = 132


# --- Player Permanent Upgrade Stats (These are NOT reset per run, they are saved/loaded) ---
# These are global multipliers/bonuses that apply to the player's core abilities.
var player_damage_percent: float = 1.0 # Global damage multiplier
var player_attack_speed :float = 4.0 # Lower is faster for cooldowns
var player_speed_percent: float = 1.0 # Global movement speed multiplier
var crit_chance: float = 0.0 # Global critical hit chance (0.0 to 1.0)
var bullet_scale: float = 1.0 # Global bullet size multiplier
var player_luck_percent: float = 1.0 # Global luck multiplier (for drops, crit, etc.)
var health_regen: float = 0.0 # Health regen per second
var gun_base_damage: float = 20.0 # Base damage for generic projectiles (can be modified by weapon-specific damage)
var crit_multiplier: float = 3.0 # Global critical hit damage multiplier

# Player core stats (also permanent, affected by upgrades)
var player_base_attack: int = 10 # This could be the base for all weapon damage calculations
var player_base_defense: int = 5
var player_health_percent:float = 1.0 # Multiplier for player's max health
var player_curse_percent:float = 1.0 # Affects enemy difficulty or negative events
var player_armor_percent:float = 0.0 # Damage reduction from enemies

# NEW: Base damage taken from touching mobs (before armor reduction)
var base_contact_damage_per_second: float = 30.0

# General game variables (can be used by various components)
var enemy_speed:float = 0.1 # This seems low, maybe a global enemy speed multiplier?
var bullet_speed:int = 500 # Default bullet speed for generic bullets
var bullet_range:int = 500 # Default bullet range for generic bullets

#Pause Menu State
var pause_menu_opened = false

# Settings (Permanent, saved/loaded)
var controls_flipped:bool= false
var vibration_enabled:bool=true
var vibration_duration_ms := 200
var vibration_amplitude := 0.5
var vibration_cooldown_sec := 0.3


# --- Audio Settings ---
var volume: float = 100.0 # This stores the *desired UNMUTED* volume (0-100)
var is_muted: bool = false # New: Stores the current mute state
var previous_unmuted_volume: float = 100.0 # New: Stores volume before muting, for unmuting


# --- Signals ---
signal item_added(item_id: String, new_count: int)
signal item_equipped_to_slot(slot_id: String, item_id: String)
signal player_gems_changed(new_total_gems: int)

func _ready() -> void:
	randomize()
	load_all_player_data()
	load_settings()
	apply_audio_settings()
	player_armor_percent = 0.0
	player_coins = 350

	if not has_node("/root/ItemData"):
		print("ERROR: Autoload 'ItemData' not found! Please add 'item_data.gd' to Project Settings -> Autoloads and name it 'ItemData'.")

	# Initial setup for new players
	if total_coins == 0 and total_gems == 0 and player_level == 1:
		print("Autoload: New player detected. Granting starting resources for testing.")
		total_coins = 1000
		total_gems = 50
		# Activate the rifle by default for new players if it's the starting weapon
		rifle_active = false # Ensure rifle is active if it's the starter
		save_all_player_data()

# --- Helper to get a specific weapon instance from the scene tree ---
# This assumes guns are grouped under "guns" and their node names match the gun type (e.g., "Rifle", "Shotgun", "Flamethrower")
func get_player_weapon_instance(weapon_name: String) -> Node:
	# The current scene (Gameplay.tscn) is likely where your guns are children of the player
	var current_scene = get_tree().current_scene
	if current_scene and current_scene.has_node("player"): # Assuming your Player node is named "player"
		var player_node = current_scene.get_node("player")
		# Check player's children first
		for child in player_node.get_children():
			if child.name.to_lower() == weapon_name.to_lower(): # Case-insensitive comparison
				return child
	
	# Fallback if not found as child of player, try the "guns" group directly (less precise but sometimes useful)
	var weapon_nodes = get_tree().get_nodes_in_group("guns") # Use the "guns" group you assigned
	for node in weapon_nodes:
		if node.name.to_lower() == weapon_name.to_lower(): # Case-insensitive comparison
			return node
	
	printerr("Autoload: Could not find weapon instance named '", weapon_name, "'. Ensure the weapon node exists, is a child of 'player', or is in the 'guns' group, and its name matches (case-insensitively).")
	return null

# --- Function to apply flamethrower upgrades (called from UI, events, etc.) ---
# This applies a specific flamethrower upgrade and updates the flamethrower instance.
func apply_flamethrower_upgrade(upgrade_type: String, value):
	var flamethrower_instance = get_player_weapon_instance("Flamethrower") # Always target Flamethrower
	
	if not flamethrower_instance:
		printerr("Autoload: Cannot apply flamethrower upgrade. Flamethrower instance not found.")
		return

	match upgrade_type:
		"fire_mode":
			# Ensure value is a valid FireMode enum
			if value is int and value >= FireMode.SINGLE_RIGHT and value <= FireMode.FOUR_SIDES:
				current_flamethrower_fire_mode = value # Update Autoload's state
				print("Autoload: Upgraded flamethrower fire mode to ", FireMode.keys()[value])
			else:
				printerr("Autoload: Invalid fire mode upgrade value: ", value)
		"duration":
			if value is String and value in ["short", "medium", "long"]:
				current_flamethrower_sound_type = value # Update Autoload's state (corrected variable name)
				# flamethrower_instance.upgrade_flamethrower_duration(value) # This might be redundant if _update_stats_from_autoload pulls this
				print("Autoload: Upgraded flamethrower duration to ", value)
			else:
				printerr("Autoload: Invalid flamethrower duration type: ", value)
		"damage":
			flamethrower_base_damage += value
			print("Autoload: Upgraded flamethrower damage by ", value, ". New damage: ", flamethrower_base_damage)
		"range":
			flamethrower_bullet_range += value
			print("Autoload: Upgraded flamethrower range by ", value, ". New range: ", flamethrower_bullet_range)
		"speed":
			flamethrower_bullet_speed += value
			print("Autoload: Upgraded flamethrower speed by ", value, ". New speed: ", flamethrower_bullet_speed)
		"reload_duration_reduction": # Renamed for clarity: we reduce the duration
			flamethrower_reload_duration = max(0.5, flamethrower_reload_duration - value) # Ensure minimum reload duration
			print("Autoload: Decreased flamethrower reload duration by ", value, ". New reload: ", flamethrower_reload_duration)
		# The 'activate' type is handled by the general `apply_gameplay_upgrade` now
		_:
			printerr("Autoload: Unknown flamethrower upgrade type for specific application: ", upgrade_type)
	
	# After any flamethrower stat is changed in Autoload, tell the flamethrower instance to re-read all its stats.
	# This replaces the individual `_update_stats_from_autoload()` calls within the match statement.
	if flamethrower_instance and flamethrower_instance.has_method("_update_stats_from_autoload"):
		flamethrower_instance._update_stats_from_autoload()
		
	# Save after any flamethrower upgrade is applied to make it persistent
	save_all_player_data()


# --- Generic function to apply any upgrade chosen during gameplay ---
# This function is called by Gameplay.gd when a player picks an upgrade.
# It modifies the permanent state (Autoload variables) based on the upgrade chosen.
# 'upgrade_type' e.g., "Rifle", "Damage", "Flamethrower_FireMode"
# 'upgrade_data' is the specific dictionary for that level of upgrade (from Gameplay.gd's all_upgrades)
func apply_gameplay_upgrade(upgrade_type: String, upgrade_data: Dictionary):
	print("Autoload: Applying gameplay upgrade: ", upgrade_type, " with data: ", upgrade_data)

	# Some upgrades will have a 'value' key, others might have 'activate_gun' etc.
	var value = upgrade_data.get("value")
	var desc = upgrade_data.get("desc") # For debugging or logging

	match upgrade_type:
		
		# --- Gun Activations (usually the first level of a gun's upgrade path) ---
		"Rifle":
			if upgrade_data.get("activate_gun", false): # Check for the 'activate_gun' flag in upgrade data
				rifle_active = true
				var rifle_instance = get_player_weapon_instance("gun") # Use consistent capitalization with node name
				if rifle_instance:
					rifle_instance.set_process_mode(Node.PROCESS_MODE_INHERIT)
					rifle_instance.show()
					if rifle_instance.has_method("_update_stats_from_autoload"):
						rifle_instance._update_stats_from_autoload()
				print("Autoload: Rifle unlocked and activated.")
			else: # Other Rifle upgrades (e.g., damage, attack speed)
				# Assuming 'value' is an increase to damage or reduction to attack speed
				if upgrade_data.has("damage_increase"): rifle_base_damage += upgrade_data.damage_increase
				if upgrade_data.has("attack_speed_increase"): rifle_attack_speed += upgrade_data.attack_speed_increase
				if upgrade_data.has("bullets_increase"): rifle_bullets += upgrade_data.bullets_increase
				
				var rifle_instance = get_player_weapon_instance("gun")
				if rifle_instance and rifle_instance.has_method("_update_stats_from_autoload"):
					rifle_instance._update_stats_from_autoload()
				print("Autoload: Rifle upgraded. New rifle_base_damage: %d, rifle_attack_speed: %f, rifle_bullets: %d" % [rifle_base_damage, rifle_attack_speed, rifle_bullets])

		"Shotgun":
			if upgrade_data.get("activate_gun", false):
				shotgun_active = true
				var shotgun_instance = get_player_weapon_instance("shotgun")
				if shotgun_instance:
					shotgun_instance.set_process_mode(Node.PROCESS_MODE_INHERIT)
					shotgun_instance.show()
					if shotgun_instance.has_method("_update_stats_from_autoload"): # If shotgun has its own update method
						shotgun_instance._update_stats_from_autoload()
				print("Autoload: Shotgun unlocked and activated.")
			else: # Other Shotgun upgrades
				if upgrade_data.has("damage_increase"): shotgun_base_damage += upgrade_data.damage_increase
				if upgrade_data.has("spread_bullets_increase"): shotgun_spread_bullets += upgrade_data.spread_bullets_increase
				if upgrade_data.has("cooldown_reduction"): shotgun_cooldown = max(0.1, shotgun_cooldown - upgrade_data.cooldown_reduction)
				if upgrade_data.has("reload_reduction"): shotgun_reload_duration = max(0.5, shotgun_reload_duration - upgrade_data.reload_reduction)
				
				var shotgun_instance = get_player_weapon_instance("shotgun")
				if shotgun_instance and shotgun_instance.has_method("_update_stats_from_autoload"):
					shotgun_instance._update_stats_from_autoload()
				print("Autoload: Shotgun upgraded. New shotgun_base_damage: %d, shotgun_spread_bullets: %d" % [shotgun_base_damage, shotgun_spread_bullets])


		"MachineGun":
			if upgrade_data.get("activate_gun", false):
				machinegun_active = true
				var machinegun_instance = get_player_weapon_instance("machinegun")
				if machinegun_instance:
					machinegun_instance.set_process_mode(Node.PROCESS_MODE_INHERIT)
					machinegun_instance.show()
					if machinegun_instance.has_method("_update_stats_from_autoload"): # Added call
						machinegun_instance._update_stats_from_autoload()
				print("Autoload: Machine Gun unlocked and activated.")
			else:
				if upgrade_data.has("damage_increase"): machinegun_base_damage += upgrade_data.damage_increase
				# Add other machine gun specific upgrades here
				var machinegun_instance = get_player_weapon_instance("machinegun")
				if machinegun_instance and machinegun_instance.has_method("_update_stats_from_autoload"):
					machinegun_instance._update_stats_from_autoload()
				print("Autoload: Machine Gun upgraded. New machinegun_base_damage: %d" % machinegun_base_damage)

		"Laser":
			if upgrade_data.get("activate_gun", false):
				laser_active = true
				var laser_instance = get_player_weapon_instance("laser")
				if laser_instance:
					laser_instance.set_process_mode(Node.PROCESS_MODE_INHERIT)
					laser_instance.show()
					if laser_instance.has_method("_update_stats_from_autoload"): # Added call
						laser_instance._update_stats_from_autoload()
				print("Autoload: Laser unlocked and activated.")
			else:
				if upgrade_data.has("damage_increase"): laser_base_damage += upgrade_data.damage_increase
				# Add other laser specific upgrades here
				var laser_instance = get_player_weapon_instance("laser")
				if laser_instance and laser_instance.has_method("_update_stats_from_autoload"):
					laser_instance._update_stats_from_autoload()
				print("Autoload: Laser upgraded. New laser_base_damage: %d" % laser_base_damage)

		"rocket":
			if upgrade_data.get("activate_gun", false):
				rocket_active = true
				var rocket_instance = get_player_weapon_instance("rocket")
				if rocket_instance:
					rocket_instance.set_process_mode(Node.PROCESS_MODE_INHERIT)
					rocket_instance.show()
					if rocket_instance.has_method("_update_stats_from_autoload"): # Added call
						rocket_instance._update_stats_from_autoload()
				print("Autoload: Rocket Launcher unlocked and activated.")
			else:
				if upgrade_data.has("damage_increase"): rocket_base_damage += upgrade_data.damage_increase
				if upgrade_data.has("explosion_size_increase"): explosion_size += upgrade_data.explosion_size_increase
				if upgrade_data.has("magazine_increase"): rocket_magazine_size += upgrade_data.magazine_increase # NEW
				if upgrade_data.has("reload_speed_increase"): rocket_reload_duration = max(0.1, rocket_reload_duration - upgrade_data.reload_speed_increase) # NEW, ensure min reload time
				
				# Add other rocket launcher specific upgrades here
				var rocket_instance = get_player_weapon_instance("rocket")
				if rocket_instance and rocket_instance.has_method("_update_stats_from_autoload"):
					rocket_instance._update_stats_from_autoload()
				print("Autoload: Rocket Launcher upgraded. New rocket_base_damage: %d, explosion_size: %f" % [rocket_base_damage, explosion_size])

		"Flamethrower":
			if upgrade_data.get("activate_gun", false):
				flamethrower_active = true
				var flamethrower_instance = get_player_weapon_instance("flamethrower")
				if flamethrower_instance:
					flamethrower_instance.set_process_mode(Node.PROCESS_MODE_INHERIT)
					flamethrower_instance.show()
					flamethrower_instance._update_stats_from_autoload() # Ensure its stats are loaded
				print("Autoload: Flamethrower unlocked and activated.")
			# Specific flamethrower stat upgrades are handled by `Flamethrower_X` below, or `apply_flamethrower_upgrade`
			
		"Shockwave":
			if upgrade_data.get("activate_gun", false):
				shockwave_active = true
				var shockwave_instance = get_player_weapon_instance("shockwave") # Or whatever your Shockwave node is named
				if shockwave_instance:
					shockwave_instance.set_process_mode(Node.PROCESS_MODE_INHERIT)
					shockwave_instance.show()
					if shockwave_instance.has_method("_update_stats_from_autoload"): # Added call
						shockwave_instance._update_stats_from_autoload()
				print("Autoload: Shockwave unlocked and activated.")
			else:
				if upgrade_data.has("damage_increase"): shockwave_base_damage += upgrade_data.damage_increase
				if upgrade_data.has("cooldown_reduction"): shockwave_cooldown = max(1.0, shockwave_cooldown - upgrade_data.cooldown_reduction) # Ensure min cooldown
				# Add other shockwave specific upgrades here
				var shockwave_instance = get_player_weapon_instance("shockwave")
				if shockwave_instance and shockwave_instance.has_method("_update_stats_from_autoload"):
					shockwave_instance._update_stats_from_autoload()
				print("Autoload: Shockwave upgraded. New shockwave_base_damage: %d, shockwave_cooldown: %f" % [shockwave_base_damage, shockwave_cooldown])


		# --- Handle Passive Upgrades (affecting player stats directly) ---
		"Damage":
			player_damage_percent += value # Assuming 'value' is an increase (e.g., 0.1 for +10%)
			print("Autoload: Player global damage multiplier increased to ", player_damage_percent)
			var player_node = get_tree().current_scene.get_node_or_null("player")
			if player_node and player_node.has_method("_update_stats"):
				player_node._update_stats() # Tell player to recalculate stats

		"Health":
			player_health_percent += value
			print("Autoload: Player max health multiplier increased to ", player_health_percent)
			var player_node = get_tree().current_scene.get_node_or_null("player")
			if player_node and player_node.has_method("_update_stats"):
				player_node._update_stats()

		"Speed":
			player_speed_percent += value
			print("Autoload: Player speed multiplier increased to ", player_speed_percent)
			var player_node = get_tree().current_scene.get_node_or_null("player")
			if player_node and player_node.has_method("_update_stats"):
				player_node._update_stats()
			
		"CritChance":
			crit_chance = min(1.0, crit_chance + value) # Cap at 1.0 (100%)
			print("Autoload: Critical chance increased to ", crit_chance)

		"CritMultiplier":
			crit_multiplier += value
			print("Autoload: Critical multiplier increased to ", crit_multiplier)
			
		"Luck":
			player_luck_percent += value
			print("Autoload: Player luck increased to ", player_luck_percent)
			
		"HealthRegen":
			health_regen += value
			print("Autoload: Health regen increased to ", health_regen)
			# If you have a separate HealthRegen node/system, update it here
			# var regen_system = get_tree().current_scene.get_node_or_null("HealthRegenSystem")
			# if regen_system and regen_system.has_method("update_regen_rate"):
			# 		regen_system.update_regen_rate(health_regen)

		# --- Specific Gun Stat Upgrades (beyond activation) ---
		# These call the dedicated `apply_flamethrower_upgrade` function
		"Flamethrower_FireMode": # This upgrade type comes from all_upgrades
			apply_flamethrower_upgrade("fire_mode", value) # Value should be the FireMode enum int
		"Flamethrower_Duration": # This is the sound duration upgrade
			apply_flamethrower_upgrade("duration", value) # Value should be "short", "medium", or "long"
		"Flamethrower_Damage":
			apply_flamethrower_upgrade("damage", value)
		"Flamethrower_Range":
			apply_flamethrower_upgrade("range", value)
		"Flamethrower_Speed": # Bullet speed
			apply_flamethrower_upgrade("speed", value)
		"Flamethrower_Reload_Reduction":
			apply_flamethrower_upgrade("reload_duration_reduction", value)

		# You would add similar specific stat upgrades for other guns here
		# E.g., "Shotgun_Damage", "Shotgun_Reload", "Rifle_AttackSpeed" etc.
		# Each would modify its corresponding `Autoload.shotgun_base_damage`, etc.
		# and then call the gun's `_update_stats_from_autoload()` if it exists.

		_:
			printerr("Autoload: Unhandled upgrade type in apply_gameplay_upgrade: ", upgrade_type, " with data: ", upgrade_data)

	save_all_player_data() # Ensure permanent state is saved after any upgrade


func reset_variables():
	# This function resets variables that are specific to the CURRENT GAME RUN.
	# It should NOT reset permanent unlocks or player account data.
	score = 0
	level = 1
	player_coins = 0 # Coins collected during the current run
	player_gems = 0 # Gems collected during the current run

	# In-run temporary buffs and base stats (these are reset each run to their baseline)
	# The permanent Autoload values (e.g., player_damage_percent from upgrades) will
	# then be applied on top of these baselines when the player's stats are calculated.
	player_damage_percent = 1.0 # This is a MULTIPLIER, so reset to 1.0
	player_attack_speed = 4.0
	player_speed_percent = 1.0
	crit_chance = 0.0 # This is the *base* crit chance for the run, permanent upgrades add to it
	bullet_scale = 1.0
	player_luck_percent = 1.0
	health_regen = 0.0
	gun_base_damage = 20.0
	crit_multiplier = 3.0
	player_health_percent = 1.0
	player_curse_percent = 1.0
	player_armor_percent = 0.0

	# Gun-specific in-run temporary stats (NOT activation status, which is permanent)
	rifle_bullets = 1
	rifle_base_damage = 15 # Reset to its initial value (or a base value if different)
	rifle_attack_speed = 1.0

	shotgun_bullets = 1
	shotgun_base_damage = 39 # Reset to its initial value
	shotgun_magazine = 6
	shotgun_spread_bullets = 5
	shotgun_cooldown = 0.3
	shotgun_reload_duration = 2.0
	shotgun_bullet_speed = 700
	shotgun_bullet_range = 500

	machinegun_bullets = 1
	machinegun_base_damage = 22 # Reset to its initial value

	laser_bullets = 1
	laser_base_damage = 42 # Reset to its initial value

	rocket_bullets = 1
	if explosion_size < 50:
		explosion_size = 50.0  # Reset to its initial value
	rocket_base_damage = 102 # Reset to its initial value

	flamethrower_bullets = 1
	flamethrower_base_damage = 52 # Reset to its initial value
	flamethrower_magazine_duration = 3.0
	flamethrower_size = 1
	flamethrower_reload_duration = 4.0
	flamethrower_bullet_speed = 700
	flamethrower_bullet_range = 500
	current_flamethrower_fire_mode = FireMode.SINGLE_RIGHT
	current_flamethrower_sound_type = "short" # Corrected variable name

	shockwave_amount = 1
	shockwave_cooldown = 5.0
	shockwave_base_damage = 132 # Reset to its initial value

	player_inventory.clear()
	player_equipped_items = {
		"equip_slot_1": "",
		"equip_slot_2": "",
		"equip_slot_3": "",
		"equip_slot_4": "",
	}

	# IMPORTANT: Permanent active flags like rifle_active, flamethrower_active,
	# total_coins, total_gems, life_token, player_level are NOT reset here.
	# They persist across runs and are managed by save/load.


# --- Unified Player Data Save/Load ---
const PLAYER_DATA_SAVE_FILE_PATH: String = "user://player_data.cfg"

func save_all_player_data():
	var config = ConfigFile.new()

	# Player Permanent Data
	config.set_value("player_data", "total_coins", total_coins)
	config.set_value("player_data", "total_gems", total_gems)
	config.set_value("player_data", "life_token", life_token)
	config.set_value("player_data", "player_level", player_level)

	# Inventory and Equipment
	config.set_value("player_data", "inventory", player_inventory)
	config.set_value("player_data", "equipped_items", player_equipped_items)
	
	# Gun Activation States (Permanent Unlocks)
	config.set_value("gun_activation", "rifle_active", rifle_active)
	config.set_value("gun_activation", "shotgun_active", shotgun_active)
	config.set_value("gun_activation", "machinegun_active", machinegun_active)
	config.set_value("gun_activation", "laser_active", laser_active)
	config.set_value("gun_activation", "rocket_active", rocket_active)
	config.set_value("gun_activation", "flamethrower_active", flamethrower_active)
	config.set_value("gun_activation", "shockwave_active", shockwave_active)

	# Flamethrower Specific Stats (Permanent Upgrades)
	config.set_value("flamethrower_stats", "flamethrower_base_damage", flamethrower_base_damage)
	config.set_value("flamethrower_stats", "flamethrower_magazine_duration", flamethrower_magazine_duration)
	config.set_value("flamethrower_stats", "flamethrower_size", flamethrower_size)
	config.set_value("flamethrower_stats", "flamethrower_reload_duration", flamethrower_reload_duration)
	config.set_value("flamethrower_stats", "flamethrower_bullet_speed", flamethrower_bullet_speed)
	config.set_value("flamethrower_stats", "flamethrower_bullet_range", flamethrower_bullet_range)
	config.set_value("flamethrower_stats", "current_flamethrower_fire_mode", current_flamethrower_fire_mode)
	config.set_value("flamethrower_stats", "current_flamethrower_sound_type", current_flamethrower_sound_type)

	# Other Gun Stats (if they have permanent upgrades)
	config.set_value("rifle_stats", "rifle_bullets", rifle_bullets)
	config.set_value("rifle_stats", "rifle_base_damage", rifle_base_damage) # Added to save
	config.set_value("rifle_stats", "rifle_attack_speed", rifle_attack_speed)

	config.set_value("shotgun_stats", "shotgun_base_damage", shotgun_base_damage) # Added to save
	config.set_value("shotgun_stats", "shotgun_magazine", shotgun_magazine)
	config.set_value("shotgun_stats", "shotgun_spread_bullets", shotgun_spread_bullets)
	config.set_value("shotgun_stats", "shotgun_cooldown", shotgun_cooldown)
	config.set_value("shotgun_stats", "shotgun_reload_duration", shotgun_reload_duration)
	config.set_value("shotgun_stats", "shotgun_bullet_speed", shotgun_bullet_speed)
	config.set_value("shotgun_stats", "shotgun_bullet_range", shotgun_bullet_range)
	config.set_value("shotgun_stats", "shotgun_bullets", shotgun_bullets)

	config.set_value("machinegun_stats", "machinegun_bullets", machinegun_bullets)
	config.set_value("machinegun_stats", "machinegun_base_damage", machinegun_base_damage) # Added to save

	config.set_value("laser_stats", "laser_bullets", laser_bullets)
	config.set_value("laser_stats", "laser_base_damage", laser_base_damage) # Added to save

	config.set_value("rocket_stats", "rocket_bullets", rocket_bullets)
	config.set_value("rocket_stats", "explosion_size", explosion_size) # Added to save
	config.set_value("rocket_stats", "rocket_base_damage", rocket_base_damage) # Added to save
	
	config.set_value("rocket_stats", "active", rocket_active)
	config.set_value("rocket_stats", "magazine_size", rocket_magazine_size) # NEW
	config.set_value("rocket_stats", "reload_duration", rocket_reload_duration) # NEW


	config.set_value("shockwave_stats", "shockwave_amount", shockwave_amount)
	config.set_value("shockwave_stats", "shockwave_cooldown", shockwave_cooldown)
	config.set_value("shockwave_stats", "shockwave_base_damage", shockwave_base_damage) # Added to save

	# Player Permanent Upgrade Stats (Passive Skills)
	config.set_value("player_permanent_stats", "player_damage_percent", player_damage_percent)
	config.set_value("player_permanent_stats", "player_attack_speed", player_attack_speed)
	config.set_value("player_permanent_stats", "player_speed_percent", player_speed_percent)
	config.set_value("player_permanent_stats", "crit_chance", crit_chance)
	config.set_value("player_permanent_stats", "bullet_scale", bullet_scale)
	config.set_value("player_permanent_stats", "player_luck_percent", player_luck_percent)
	config.set_value("player_permanent_stats", "health_regen", health_regen)
	config.set_value("player_permanent_stats", "gun_base_damage", gun_base_damage)
	config.set_value("player_permanent_stats", "crit_multiplier", crit_multiplier)
	config.set_value("player_permanent_stats", "player_base_attack", player_base_attack)
	config.set_value("player_permanent_stats", "player_base_defense", player_base_defense)
	config.set_value("player_permanent_stats", "player_health_percent", player_health_percent)
	config.set_value("player_permanent_stats", "player_curse_percent", player_curse_percent)
	config.set_value("player_permanent_stats", "player_armor_percent", player_armor_percent)
	config.set_value("player_permanent_stats", "base_contact_damage_per_second", base_contact_damage_per_second)

	var error = config.save(PLAYER_DATA_SAVE_FILE_PATH)
	if error != OK:
		print("ERROR: Failed to save player data to ", PLAYER_DATA_SAVE_FILE_PATH, ". Error code: ", error)
	else:
		print("PLAYER_DATA: All player data saved successfully.")


func load_all_player_data():
	var config = ConfigFile.new()
	var error = config.load(PLAYER_DATA_SAVE_FILE_PATH)
	if error == OK:
		# Load Player Permanent Data
		total_coins = config.get_value("player_data", "total_coins", 0)
		total_gems = config.get_value("player_data", "total_gems", 0)
		life_token = config.get_value("player_data", "life_token", 0)
		player_level = config.get_value("player_data", "player_level", 1)

		# Load Inventory
		player_inventory = config.get_value("player_data", "inventory", {})

		# Load Equipped Items
		player_equipped_items = config.get_value("player_data", "equipped_items", {
			"equip_slot_1": "",
			"equip_slot_2": "",
			"equip_slot_3": "",
			"equip_slot_4": "",
		})
		
		# Load Gun Activation States
		rifle_active = config.get_value("gun_activation", "rifle_active", false)
		shotgun_active = config.get_value("gun_activation", "shotgun_active", false)
		machinegun_active = config.get_value("gun_activation", "machinegun_active", false)
		laser_active = config.get_value("gun_activation", "laser_active", false)
		rocket_active = config.get_value("gun_activation", "rocket_active", false)
		flamethrower_active = config.get_value("gun_activation", "flamethrower_active", false)
		shockwave_active = config.get_value("gun_activation", "shockwave_active", false)

		# Load Flamethrower Specific Stats
		flamethrower_base_damage = config.get_value("flamethrower_stats", "flamethrower_base_damage", flamethrower_base_damage)
		flamethrower_magazine_duration = config.get_value("flamethrower_stats", "flamethrower_magazine_duration", flamethrower_magazine_duration)
		flamethrower_size = config.get_value("flamethrower_stats", "flamethrower_size", flamethrower_size)
		flamethrower_reload_duration = config.get_value("flamethrower_stats", "flamethrower_reload_duration", flamethrower_reload_duration)
		flamethrower_bullet_speed = config.get_value("flamethrower_stats", "flamethrower_bullet_speed", flamethrower_bullet_speed)
		flamethrower_bullet_range = config.get_value("flethrower_stats", "flamethrower_bullet_range", flamethrower_bullet_range)
		current_flamethrower_fire_mode = config.get_value("flamethrower_stats", "current_flamethrower_fire_mode", current_flamethrower_fire_mode)
		current_flamethrower_sound_type = config.get_value("flamethrower_stats", "current_flamethrower_sound_type", current_flamethrower_sound_type)

		# Load Other Gun Stats (if they have permanent upgrades)
		rifle_bullets = config.get_value("rifle_stats", "rifle_bullets", rifle_bullets)
		rifle_base_damage = config.get_value("rifle_stats", "rifle_base_damage", rifle_base_damage) # Added to load
		rifle_attack_speed = config.get_value("rifle_stats", "rifle_attack_speed", rifle_attack_speed)

		shotgun_base_damage = config.get_value("shotgun_stats", "shotgun_base_damage", shotgun_base_damage) # Added to load
		shotgun_magazine = config.get_value("shotgun_stats", "shotgun_magazine", shotgun_magazine)
		shotgun_spread_bullets = config.get_value("shotgun_stats", "shotgun_spread_bullets", shotgun_spread_bullets)
		shotgun_cooldown = config.get_value("shotgun_stats", "shotgun_cooldown", shotgun_cooldown)
		shotgun_reload_duration = config.get_value("shotgun_stats", "shotgun_reload_duration", shotgun_reload_duration)
		shotgun_bullet_speed = config.get_value("shotgun_stats", "shotgun_bullet_speed", shotgun_bullet_speed)
		shotgun_bullet_range = config.get_value("shotgun_stats", "shotgun_bullet_range", shotgun_bullet_range)
		shotgun_bullets = config.get_value("shotgun_stats", "shotgun_bullets", shotgun_bullets)

		machinegun_bullets = config.get_value("machinegun_stats", "machinegun_bullets", machinegun_bullets)
		machinegun_base_damage = config.get_value("machinegun_stats", "machinegun_base_damage", machinegun_base_damage) # Added to load

		laser_bullets = config.get_value("laser_stats", "laser_bullets", laser_bullets)
		laser_base_damage = config.get_value("laser_stats", "laser_base_damage", laser_base_damage) # Added to load

		rocket_bullets = config.get_value("rocket_stats", "rocket_bullets", rocket_bullets)
		#explosion_size = config.get_value("rocket_stats", "explosion_size", explosion_size) # Added to load
		#rocket_base_damage = config.get_value("rocket_stats", "rocket_base_damage", rocket_base_damage) # Added to load
		
		# Rocket Launcher Loads
		rocket_active = config.get_value("rocket_stats", "active", rocket_active)
		rocket_base_damage = config.get_value("rocket_stats", "base_damage", rocket_base_damage)
		explosion_size = config.get_value("rocket_stats", "explosion_size", explosion_size)
		rocket_magazine_size = config.get_value("rocket_stats", "magazine_size", rocket_magazine_size) # NEW
		rocket_reload_duration = config.get_value("rocket_stats", "reload_duration", rocket_reload_duration) # NEW


		shockwave_amount = config.get_value("shockwave_stats", "shockwave_amount", shockwave_amount)
		shockwave_cooldown = config.get_value("shockwave_stats", "shockwave_cooldown", shockwave_cooldown)
		shockwave_base_damage = config.get_value("shockwave_stats", "shockwave_base_damage", shockwave_base_damage) # Added to load

		# Load Player Permanent Upgrade Stats (Passive Skills)
		player_damage_percent = config.get_value("player_permanent_stats", "player_damage_percent", player_damage_percent)
		player_attack_speed = config.get_value("player_permanent_stats", "player_attack_speed", player_attack_speed)
		player_speed_percent = config.get_value("player_permanent_stats", "player_speed_percent", player_speed_percent)
		crit_chance = config.get_value("player_permanent_stats", "crit_chance", crit_chance)
		bullet_scale = config.get_value("player_permanent_stats", "bullet_scale", bullet_scale)
		player_luck_percent = config.get_value("player_permanent_stats", "player_luck_percent", player_luck_percent)
		health_regen = config.get_value("player_permanent_stats", "health_regen", health_regen)
		gun_base_damage = config.get_value("player_permanent_stats", "gun_base_damage", gun_base_damage)
		crit_multiplier = config.get_value("player_permanent_stats", "crit_multiplier", crit_multiplier)
		player_base_attack = config.get_value("player_permanent_stats", "player_base_attack", player_base_attack)
		player_base_defense = config.get_value("player_permanent_stats", "player_base_defense", player_base_defense)
		player_health_percent = config.get_value("player_permanent_stats", "player_health_percent", player_health_percent)
		player_curse_percent = config.get_value("player_permanent_stats", "player_curse_percent", player_curse_percent)
		player_armor_percent = config.get_value("player_permanent_stats", "player_armor_percent", player_armor_percent)
		base_contact_damage_per_second = config.get_value("player_permanent_stats", "base_contact_damage_per_second", base_contact_damage_per_second)
		print("PLAYER_DATA: Player data loaded successfully.")
	elif error == ERR_FILE_NOT_FOUND:
		print("PLAYER_DATA: No player save file found. Starting with default values.")
	else:
		print("ERROR: Failed to load player data from ", PLAYER_DATA_SAVE_FILE_PATH, ". Error code: ", error)


func load_settings():
	var config = ConfigFile.new()
	var error = config.load("user://game_settings.cfg")
	if error == OK:
		controls_flipped = config.get_value("settings", "controls_flipped", false)
		vibration_enabled = config.get_value("settings", "vibration_enabled", true)
		vibration_duration_ms = config.get_value("settings", "vibration_duration_ms", 200)
		vibration_amplitude = config.get_value("settings", "vibration_amplitude", 0.5)
		vibration_cooldown_sec = config.get_value("settings", "vibration_cooldown_sec", 0.3)
		
		# Audio settings
		volume = config.get_value("audio", "volume", 100.0)
		is_muted = config.get_value("audio", "is_muted", false)
		previous_unmuted_volume = config.get_value("audio", "previous_unmuted_volume", 100.0)
		print("SETTINGS: Game settings loaded successfully.")
	elif error == ERR_FILE_NOT_FOUND:
		print("SETTINGS: No settings file found. Starting with default settings.")
	else:
		print("ERROR: Failed to load game settings. Error code: ", error)

func save_settings():
	var config = ConfigFile.new()
	config.set_value("settings", "controls_flipped", controls_flipped)
	config.set_value("settings", "vibration_enabled", vibration_enabled)
	config.set_value("settings", "vibration_duration_ms", vibration_duration_ms)
	config.set_value("settings", "vibration_amplitude", vibration_amplitude)
	config.set_value("settings", "vibration_cooldown_sec", vibration_cooldown_sec)

	# Audio settings
	config.set_value("audio", "volume", volume)
	config.set_value("audio", "is_muted", is_muted)
	config.set_value("audio", "previous_unmuted_volume", previous_unmuted_volume)

	var error = config.save("user://game_settings.cfg")
	if error != OK:
		print("ERROR: Failed to save game settings. Error code: ", error)
	else:
		print("SETTINGS: Game settings saved successfully.")


func apply_audio_settings():
	# Example of how you might apply audio settings globally
	if AudioServer.get_bus_index("Master") != -1:
		if is_muted:
			AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), true)
		else:
			AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(volume / 100.0))
		print("AUDIO: Applied audio settings. Volume: %f, Muted: %s" % [volume, is_muted])
	else:
		printerr("AUDIO: Master audio bus not found. Cannot apply audio settings.")


# --- Inventory Management Functions ---
func add_item_to_inventory(item_id: String, quantity: int = 1) -> void:
	if player_inventory.has(item_id):
		player_inventory[item_id] += quantity
	else:
		player_inventory[item_id] = quantity
	print("INVENTORY: Added ", quantity, " of ", item_id, ". Total: ", player_inventory[item_id])
	save_all_player_data()
	item_added.emit(item_id, player_inventory[item_id])

func remove_item_from_inventory(item_id: String, quantity: int = 1) -> bool:
	if player_inventory.has(item_id) and player_inventory[item_id] >= quantity:
		player_inventory[item_id] -= quantity
		if player_inventory[item_id] <= 0:
			player_inventory.erase(item_id)
		print("INVENTORY: Removed ", quantity, " of ", item_id, ". Remaining: ", player_inventory.get(item_id, 0))
		save_all_player_data()
		return true
	print("INVENTORY ERROR: Cannot remove ", quantity, " of ", item_id, ". Not enough in inventory or item not found.")
	return false

func get_item_count(item_id: String) -> int:
	return player_inventory.get(item_id, 0)


# --- Equipment Management Functions ---
func get_equipped_item_id(slot_id: String) -> String:
	return player_equipped_items.get(slot_id, "")

func get_all_equipped_items() -> Dictionary:
	return player_equipped_items.duplicate()



func equip_item(slot_id: String, item_id_to_equip: String) -> void:
	var currently_equipped_id = player_equipped_items.get(slot_id, "")
	if not currently_equipped_id.is_empty():
		add_item_to_inventory(currently_equipped_id, 1)

	if not item_id_to_equip.is_empty():
		if remove_item_from_inventory(item_id_to_equip, 1):
			player_equipped_items[slot_id] = item_id_to_equip
			print("GLOBAL: Equipped '", item_id_to_equip, "' to '", slot_id, "'")
			item_equipped_to_slot.emit(slot_id, item_id_to_equip)
			print("DEBUG: item_equipped_to_slot signal emitted for slot: ", slot_id)
		else:
			print("GLOBAL WARNING: Could not equip '", item_id_to_equip, "' to '", slot_id, "' (not in inventory or not enough quantity).")
			player_equipped_items[slot_id] = ""
	else:
		player_equipped_items[slot_id] = ""
	print("GLOBAL: Unequipped item from '", slot_id, "' (selected None slot).")

	save_all_player_data()


func unequip_item(slot_id: String) -> void:
	var currently_equipped_id = player_equipped_items.get(slot_id, "")
	if not currently_equipped_id.is_empty():
		add_item_to_inventory(currently_equipped_id, 1)
		player_equipped_items[slot_id] = ""
		print("GLOBAL: Unequipped '", currently_equipped_id, "' from '", slot_id, "'")
	else:
		print("GLOBAL: Nothing to unequip in slot '", slot_id, "'")

	save_all_player_data()

# --- Currency Management ---
func add_coins(amount: int):
	if amount < 0:
		printerr("Autoload: Cannot add negative coins.")
		return
	total_coins += amount
	player_coins += amount # Also add to current run coins
	print("Autoload: Added ", amount, " coins. Total: ", total_coins, ", Current Run: ", player_coins)
	save_all_player_data()

func deduct_coins(amount: int) -> bool:
	if amount < 0:
		printerr("Autoload: Cannot deduct negative coins.")
		return false
	if total_coins >= amount:
		total_coins -= amount
		print("Autoload: Deducted ", amount, " coins. Remaining total: ", total_coins)
		save_all_player_data()
		return true
	print("Autoload: Not enough coins to deduct ", amount, ". Current total: ", total_coins)
	return false

func add_gems(amount: int):
	if amount < 0:
		printerr("Autoload: Cannot add negative gems.")
		return
	total_gems += amount
	player_gems += amount # Also add to current run gems
	print("Autoload: Added ", amount, " gems. Total: ", total_gems, ", Current Run: ", player_gems)
	save_all_player_data()
	player_gems_changed.emit(total_gems)

func deduct_gems(amount: int) -> bool:
	if amount < 0:
		printerr("Autoload: Cannot deduct negative gems.")
		return false
	if total_gems >= amount:
		total_gems -= amount
		print("Autoload: Deducted ", amount, " gems. Remaining total: ", total_gems)
		save_all_player_data()
		player_gems_changed.emit(total_gems)
		return true
	print("Autoload: Not enough gems to deduct ", amount, ". Current total: ", total_gems)
	return false

func add_life_token(amount: int):
	if amount < 0:
		printerr("Autoload: Cannot add negative life tokens.")
		return
	life_token += amount
	print("Autoload: Added ", amount, " life tokens. Total: ", life_token)
	save_all_player_data()

func deduct_life_token(amount: int = 1) -> bool:
	if amount < 0:
		printerr("Autoload: Cannot deduct negative life tokens.")
		return false
	if life_token >= amount:
		life_token -= amount
		print("Autoload: Deducted ", amount, " life tokens. Remaining total: ", life_token)
		save_all_player_data()
		return true
	print("Autoload: Not enough life tokens to deduct ", amount, ". Current total: ", life_token)
	return false


# --- XP and Leveling ---
func add_score(amount: int):
	if amount < 0:
		printerr("Autoload: Cannot add negative score.")
		return
	score += amount
	print("Autoload: Added ", amount, " score. Current score: ", score)
	# You would typically have a leveling system that checks score here
	# For example: check_for_level_up()

func increment_player_level():
	player_level += 1
	print("Autoload: Player permanent level increased to ", player_level)
	save_all_player_data()

func get_mob_xp_value(mob_type: String) -> int:
	return mob_stats.get(mob_type, {}).get("xp_value", 0)

func get_mob_coin_chance(mob_type: String) -> float:
	return mob_stats.get(mob_type, {}).get("coin_chance", 0.0)

# --- Audio Toggling ---
func toggle_mute_audio():
	is_muted = not is_muted
	if is_muted:
		previous_unmuted_volume = volume # Store current volume before muting
		volume = 0.0
	else:
		volume = previous_unmuted_volume # Restore volume from before muting
	
	apply_audio_settings()
	save_settings()

func set_audio_volume(new_volume: float):
	volume = clamp(new_volume, 0.0, 100.0)
	is_muted = (volume == 0.0) # If volume is set to 0, consider it muted
	if not is_muted:
		previous_unmuted_volume = volume # Update previous unmuted volume if not muted
	
	apply_audio_settings()
	save_settings()

# Example: How player stats might be updated during gameplay (called from Player.gd)
# func _process(delta: float) -> void:
#    # This might be called if there's a continuous effect that updates player stats
#    # based on Autoload variables (e.g., health regen)
#    var player_node = get_tree().current_scene.get_node_or_null("player")
#    if player_node and player_node.has_method("_update_stats"):
#        player_node._update_stats()
