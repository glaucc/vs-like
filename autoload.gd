# Autoload.gd
extends Node

# --- Core Player Stats (These are usually reset per run or represent current run progress) ---
var player_coins: int = 0 # Coins collected during the current run
var player_gems: int = 0 # Gems collected during the current run, added to total_gems at end of run

# --- Player Permanent Data (to be saved/loaded) ---
var player_level: int = 1 # This is the permanent player account level (e.g., used for shop unlocks)
var total_coins: int = 0 # Total coins for shop/permanent purchases
var total_gems: int = 0 # Total gems for shop/premium currency (PERMANENT SAVE)
var life_token: int = 2 # Revive tokens (Permanent, deducts from this pool)


# --- Game State (Current run progress) ---
var score: int = 0 # XP collected during the current run
var level: int = 1 # Current in-game level (XP level)


# Mobs (This data should ideally be in a separate Autoload like 'MobData' if it's purely data)
# For now, I'll assume it's okay here but flag for potential refactor.
var mob_stats = {
	"mob": {"base_health": 40, "base_speed": 100, "xp_value": 1, "coin_chance": 0.2},
	"bat": {"base_health": 2000, "base_speed": 120, "xp_value": 50, "coin_chance": 0.15},
	"python": {"base_health": 80, "base_speed": 80, "xp_value": 2, "coin_chance": 0.3},
	"psycho": {"base_health": 120, "base_speed": 90, "xp_value": 3, "coin_chance": 0.25}, # Added psycho based on PoolManager
	"boss1": {"base_health": 5000, "base_speed": 60, "xp_value": 500, "coin_chance": 0.5},
	"bull_boss": {"base_health": 7000, "base_speed": 70, "xp_value": 700, "coin_chance": 0.6},
	"giant_boss": {"base_health": 10000, "base_speed": 50, "xp_value": 1000, "coin_chance": 0.7},
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
## GUNS (In-run upgrades)
##----------------------------------

# Gun 1 (Rifle/Pistol) - Changed 'gun1_active' to 'rifle_active' as per your code
var rifle_active: bool = true
var rifle_bullets: int = 1
var rifle_attack_speed: float = 1.0

# Gun 2 (Shotgun)
var shotgun_active: bool = false
var shotgun_bullets: int = 1

# Gun 3 (Machine Gun)
var machinegun_active: bool = false
var machinegun_bullets: int = 1

# Gun 4 (Laser)
var laser_active: bool = false
var laser_bullets: int = 1

# Gun 5 (Rocket Launcher)
var rocket_active: bool = false
var rocket_bullets: int = 1

# Gun 6 (Flame Thrower)
var flamethrower_active: bool = false
var flamethrower_bullets: int = 1

# --- Player Upgrade Stats (These are also usually reset per run) ---
var player_damage_percent: float = 1.0
var player_attack_speed :float = 4.0 # Lower is faster for cooldowns
var player_speed_percent: float = 1.0
var crit_chance: float = 0.0
var bullet_scale: float = 1.0
var player_luck_percent: float = 1.0
var health_regen: float = 0.0
var gun_base_damage: float = 20.0 # Reverted to 20.0 here for consistency
var crit_multiplier: float = 3.0 # Consider making this an upgrade too

# Shotgun specific stats (In-run upgrades)
var shotgun_base_damage: int = 40
var shotgun_magazine: int = 6
var shotgun_spread_bullets: int = 5
var shotgun_cooldown: float = 0.3
var shotgun_reload_duration: float = 2.0
var shotgun_bullet_speed: int = 700
var shotgun_bullet_range: int = 500

# Other player-related stats from your original
var player_base_attack: int = 10 # Base attack stat for player (used by GameMenu)
var player_base_defense: int = 5 # Base defense stat for player (used by GameMenu)
var enemy_speed:float = 0.1 # This feels like it should be `mob_stats` or a global game difficulty setting
var bullet_speed:int = 500 # This is a base, individual guns might override/modify
var bullet_range:int = 500 # This is a base, individual guns might override/modify
var player_health_percent:float = 1.0 # This might be total health percentage from upgrades
var player_curse_percent:float = 1.0
var player_armor_percent:float = 1.0 # This should be a damage *reduction* percentage (0.0 to 1.0)

# NEW: Base damage taken from touching mobs (before armor reduction)
var base_contact_damage_per_second: float = 30.0 # Example: 30 damage per second from contact

# Settings
var controls_flipped:bool= false
var vibration_enabled:bool=true
var vibration_duration_ms := 200
var vibration_amplitude := 0.5
var vibration_cooldown_sec := 0.3

# --- Signals ---
signal item_added(item_id: String, new_count: int)
signal item_equipped_to_slot(slot_id: String, item_id: String)
signal player_gems_changed(new_total_gems: int) # New signal for when total_gems changes

func _ready() -> void:
	randomize()
	load_all_player_data()
	load_settings()

	if not has_node("/root/ItemData"):
		print("ERROR: Autoload 'ItemData' not found! Please add 'item_data.gd' to Project Settings -> Autoloads and name it 'ItemData'.")

	# Example of adding initial coins/gems for new players or testing
	if total_coins == 0 and total_gems == 0 and player_level == 1:
		print("Autoload: New player detected. Granting starting resources for testing.")
		total_coins = 1000
		total_gems = 50 # Give some starting gems for new players
		save_all_player_data()


func reset_variables():
	# Reset in-game specific stats that should start fresh each run
	score = 0
	level = 1 # In-game level
	player_coins = 0 # Reset current run coins
	player_gems = 0 # Reset current run gems

	player_damage_percent = 1.0
	player_attack_speed = 4.0
	player_speed_percent = 1.0
	crit_chance = 0.0
	bullet_scale = 1.0
	player_luck_percent = 1.0
	health_regen = 0.0
	gun_base_damage = 20.0 # Consistent with the top of Autoload
	crit_multiplier = 3.0
	player_health_percent = 1.0 # Reset to base
	player_curse_percent = 1.0 # Reset to base
	player_armor_percent = 1.0 # Reset to base (meaning no reduction if 1.0 implies 0% reduction)
							   # If 1.0 means 100% reduction, set to 0.0 for no reduction.
							   # I'll adjust the `take_damage` to treat `player_armor_percent` as a direct reduction.

	# Reset gun activations and stats for a new run
	rifle_active = true
	rifle_bullets = 1
	rifle_attack_speed = 1.0

	shotgun_active = false
	shotgun_bullets = 1
	shotgun_base_damage = 40 # Consistent with the top of Autoload
	shotgun_magazine = 6
	shotgun_spread_bullets = 5
	shotgun_cooldown = 0.3
	shotgun_reload_duration = 2.0
	shotgun_bullet_speed = 700
	shotgun_bullet_range = 500

	machinegun_active = false
	machinegun_bullets = 1

	laser_active = false
	laser_bullets = 1

	rocket_active = false
	rocket_bullets = 1

	flamethrower_active = false
	flamethrower_bullets = 1

	# NOTE: player_inventory and player_equipped_items should generally NOT be reset here
	# if they represent permanent player progression. If they are reset here,
	# it means you want to lose all items and equipment at the start of each run,
	# which is usually not desired for a roguelite/survivors-like game where
	# permanent upgrades are key.
	# If they are temporary for a run, move them to a run-specific script.
	# For now, I'll keep them as they are in your provided `reset_variables`,
	# assuming this is intended behavior.

	player_inventory.clear()
	player_equipped_items = {
		"equip_slot_1": "",
		"equip_slot_2": "",
		"equip_slot_3": "",
		"equip_slot_4": "",
	}
	# Do NOT call save_all_player_data() here after clearing.
	# The `reset_variables` func is for a *new run*, not to erase permanent data.
	# Permanent data is saved in `finalize_game_over` based on `total_coins` and `total_gems`.


# --- Unified Player Data Save/Load ---
const PLAYER_DATA_SAVE_FILE_PATH: String = "user://player_data.cfg" # Central save file

func save_all_player_data():
	var config = ConfigFile.new()

	# Save permanent data
	config.set_value("player_data", "total_coins", total_coins)
	config.set_value("player_data", "total_gems", total_gems) # Save total gems
	config.set_value("player_data", "life_token", life_token) # Save life tokens
	config.set_value("player_data", "player_level", player_level) # Save permanent player level

	# Save inventory (if it's meant to be permanent)
	config.set_value("player_data", "inventory", player_inventory)

	# Save equipped items (if they're meant to be permanent)
	config.set_value("player_data", "equipped_items", player_equipped_items)

	var error = config.save(PLAYER_DATA_SAVE_FILE_PATH)
	if error != OK:
		print("ERROR: Failed to save player data to ", PLAYER_DATA_SAVE_FILE_PATH, ". Error code: ", error)
	else:
		print("PLAYER_DATA: All player data saved successfully.")


func load_all_player_data():
	var config = ConfigFile.new()
	var error = config.load(PLAYER_DATA_SAVE_FILE_PATH)
	if error == OK:
		# Load permanent data
		total_coins = config.get_value("player_data", "total_coins", 0)
		total_gems = config.get_value("player_data", "total_gems", 0) # Load total gems
		life_token = config.get_value("player_data", "life_token", 2) # Load life tokens, default to 2
		player_level = config.get_value("player_data", "player_level", 1) # Load permanent player level

		# Load inventory
		player_inventory = config.get_value("player_data", "inventory", {})

		# Load equipped items
		player_equipped_items = config.get_value("player_data", "equipped_items", {
			"equip_slot_1": "",
			"equip_slot_2": "",
			"equip_slot_3": "",
			"equip_slot_4": "",
		})
		print("PLAYER_DATA: All player data loaded successfully.")
	else:
		print("PLAYER_DATA: No player data file found at ", PLAYER_DATA_SAVE_FILE_PATH, ". Starting with default values.")


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

func get_all_inventory_items() -> Dictionary:
	return player_inventory.duplicate()

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

# --- Coin Management ---
func add_coins(amount: int) -> void:
	player_coins += amount
	# Coins are only added to total_coins at the end of a run (in Gameplay.gd)
	# save_all_player_data() # Removed this as coins are added to total at end of run.

# --- Gem Management (New) ---
func add_gems(amount: int) -> void:
	player_gems += amount # Add to current run's gems
	# Gems are added to total_gems at the end of a run (in Gameplay.gd)
	# emit_signal("player_gems_changed", total_gems) # Signal can be emitted when total_gems is updated

# --- Settings Save/Load (Existing, untouched) ---
func save_settings():
	var config = ConfigFile.new()
	config.set_value("controls", "flipped", controls_flipped)
	config.set_value("vibration", "enabled", vibration_enabled)
	config.set_value("vibration", "duration_ms", vibration_duration_ms)
	config.set_value("vibration", "amplitude", vibration_amplitude)
	config.set_value("vibration", "cooldown_sec", vibration_cooldown_sec)
	config.save("user://settings.cfg")

func load_settings():
	var config = ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		controls_flipped = config.get_value("controls", "flipped", false)
		vibration_enabled = config.get_value("vibration", "enabled", true)
		vibration_duration_ms = config.get_value("vibration", "duration_ms", 200)
		vibration_amplitude = config.get_value("vibration", "amplitude", 0.5)
		vibration_cooldown_sec = config.get_value("vibration", "cooldown_sec", 0.3)
