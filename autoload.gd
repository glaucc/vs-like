# Autoload.gd
extends Node

# --- Core Player Stats ---
var player_coins: int = 0
var player_base_attack: int = 10 # Base attack stat for player (used by GameMenu)
var player_base_defense: int = 5 # Base defense stat for player (used by GameMenu)
var player_level:int = 1

# --- Inventory and Equipment ---
# Inventory: Dictionary mapping item 'id' (String) to quantity (int)
var player_inventory: Dictionary = {}

# Equipped items: Dictionary mapping slot_id (String) to item 'id' (String)
var player_equipped_items: Dictionary = {
	"equip_slot_1": "", # Default empty string for no item
	"equip_slot_2": "",
	"equip_slot_3": "",
	"equip_slot_4": "",
	# Add more slot IDs here if you have more than 4 equip slots in your UI
}

# --- Game State Variables (from your original script) ---
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

# Settings
var controls_flipped:bool= false
var vibration_enabled:bool=true
var vibration_duration_ms := 200
var vibration_amplitude := 0.5
var vibration_cooldown_sec := 0.3

# --- Signals ---
signal item_added(item_id: String, new_count: int)
# NEW: A signal to notify when an item is equipped (and which slot)
signal item_equipped_to_slot(slot_id: String, item_id: String)


func _ready() -> void:
	# IMPORTANT: Call randomize() once at the start of your game to ensure different random numbers each run.
	randomize() 

	load_all_player_data() # Load existing data

	# For testing, you can force add items here regardless of loaded data
	#print("Autoload: Forcing addition of starter items for testing.")
	#add_item_to_inventory("common_sword", 1)
	#add_item_to_inventory("black_common_sword", 1)
	#add_item_to_inventory("Icon1_common", 2) # Example of image-based item
	#add_item_to_inventory("book1_common", 1) # Example of image-based item
	#player_coins = 1000 # Ensure you have some coins if you rely on that check

	# You might comment out or remove this block during debugging if you force add above
	# if player_inventory.is_empty() and player_coins == 0:
	#     print("Autoload: No existing player data, adding starter items for testing.")
	#     add_item_to_inventory("common_sword", 1)
	#     add_item_to_inventory("black_common_sword", 1)
	player_coins = 1000
	#     save_all_player_data()


	load_settings()

	if not has_node("/root/ItemData"):
		print("ERROR: Autoload 'ItemData' not found! Please add 'item_data.gd' to Project Settings -> Autoloads and name it 'ItemData'.")



func reset_variables():
	level = 1
	bullet_speed = 500
	score = 0
	player_inventory.clear() # Clear inventory on reset
	player_equipped_items = { # Reset equipped items
		"equip_slot_1": "",
		"equip_slot_2": "",
		"equip_slot_3": "",
		"equip_slot_4": "",
	}
	save_all_player_data() # Save the reset state

# --- Unified Player Data Save/Load ---
const PLAYER_DATA_SAVE_FILE_PATH: String = "user://player_data.cfg" # Central save file



func save_all_player_data():
	var config = ConfigFile.new()

	# Save coins
	config.set_value("player_data", "coins", player_coins)

	# Save inventory
	config.set_value("player_data", "inventory", player_inventory)

	# Save equipped items
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
		player_coins = config.get_value("player_data", "coins", 0)
		player_inventory = config.get_value("player_data", "inventory", {}) # Default to empty dict if not found
		player_equipped_items = config.get_value("player_data", "equipped_items", {
			"equip_slot_1": "", # Ensure defaults match your slot structure
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
	save_all_player_data() # Save after every change
	item_added.emit(item_id, player_inventory[item_id]) # Emit the signal

func remove_item_from_inventory(item_id: String, quantity: int = 1) -> bool:
	if player_inventory.has(item_id) and player_inventory[item_id] >= quantity:
		player_inventory[item_id] -= quantity
		if player_inventory[item_id] <= 0:
			player_inventory.erase(item_id) # Remove entry if quantity drops to 0 or less
		print("INVENTORY: Removed ", quantity, " of ", item_id, ". Remaining: ", player_inventory.get(item_id, 0))
		save_all_player_data() # Save after every change
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

# NEW FUNCTION: Returns a copy of the dictionary of all currently equipped items
func get_all_equipped_items() -> Dictionary:
	return player_equipped_items.duplicate() # Return a copy to prevent external modification



func equip_item(slot_id: String, item_id_to_equip: String) -> void:
	# If there's an item currently equipped in this slot, unequip it first
	var currently_equipped_id = player_equipped_items.get(slot_id, "")
	if not currently_equipped_id.is_empty():
		add_item_to_inventory(currently_equipped_id, 1) # Return the item to inventory

	# Now, equip the new item
	if not item_id_to_equip.is_empty(): # If we're not trying to unequip (by passing empty string)
		# Try to remove 1 from inventory to equip it
		if remove_item_from_inventory(item_id_to_equip, 1): #
			player_equipped_items[slot_id] = item_id_to_equip
			print("GLOBAL: Equipped '", item_id_to_equip, "' to '", slot_id, "'") #
			
			# --- NEW: Emit signal after successful equip ---
			item_equipped_to_slot.emit(slot_id, item_id_to_equip)
			print("DEBUG: item_equipped_to_slot signal emitted for slot: ", slot_id)

		else:
			print("GLOBAL WARNING: Could not equip '", item_id_to_equip, "' to '", slot_id, "' (not in inventory or not enough quantity).")
			# Ensure the slot is empty if equipping failed
			player_equipped_items[slot_id] = ""
	else:
		# If item_id_to_equip is empty, it means we are explicitly unequipping (e.g. from "None" slot)
		player_equipped_items[slot_id] = ""
		print("GLOBAL: Unequipped item from '", slot_id, "' (selected None slot).")

	save_all_player_data() # Save after equipment changes



func unequip_item(slot_id: String) -> void:
	var currently_equipped_id = player_equipped_items.get(slot_id, "")
	if not currently_equipped_id.is_empty():
		add_item_to_inventory(currently_equipped_id, 1) # Return to inventory
		player_equipped_items[slot_id] = ""
		print("GLOBAL: Unequipped '", currently_equipped_id, "' from '", slot_id, "'")
	else:
		print("GLOBAL: Nothing to unequip in slot '", slot_id, "'")

	save_all_player_data() # Save after equipment changes

# --- Coin Management ---
func add_coins(amount: int) -> void:
	player_coins += amount
	save_all_player_data()

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
