# ItemData.gd
extends Node

# Path to your Item.gd script
const ITEM_CLASS = preload("res://resources/item.gd") # <--- ENSURE THIS PATH IS CORRECT!

# Directory where your .tres Item resources are stored
const ITEMS_RESOURCES_DIR = "res://resources/items/data/" # <--- ADJUST THIS PATH to where you store your .tres files!

# NEW: Define Random Attack Bonus Ranges
const ATTACK_BONUS_RANGES = {
	"common": { "min": 2, "max": 15 },
	"rare": { "min": 18, "max": 28 },
	"epic": { "min": 35, "max": 60 },
	"legendary": { "min": 95, "max": 500 }
}

const DEFENSE_BONUS_RANGES = {
	"common": { "min": 1, "max": 10 },
	"rare": { "min": 12, "max": 20 },
	"epic": { "min": 25, "max": 45 },
	"legendary": { "min": 60, "max": 250 } # Legendary can be quite high
}

var _loaded_item_resources: Dictionary = {} # Stores Item resources loaded from .tres files
var _generated_item_cache: Dictionary = {}  # Cache for dynamically generated Item resources (from images)
var _full_paths_map: Dictionary = {}        # Maps item_id to its full texture path (for image-based items)

func _ready() -> void:
	# Important: Ensure random number generator is initialized once
	randomize() # Call this somewhere at game start, e.g., your main scene's _ready() or Autoload's _ready().

	print("ItemData: Initializing item database...")
	_load_all_item_resources()
	print("DEBUG: Populating items_by_rarity_dict dynamically (if used for non-.tres assets)...")
	_add_item_paths_from_dirs() # This is where your PNGs are scanned for other items
	print("ItemData: Item database initialized. Loaded ", _loaded_item_resources.size(), " .tres items and registered ", _full_paths_map.size(), " image paths.")


func _load_all_item_resources() -> void:
	_loaded_item_resources.clear()
	var dir = DirAccess.open(ITEMS_RESOURCES_DIR)

	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var full_path = ITEMS_RESOURCES_DIR + file_name
				var loaded_resource = load(full_path)
				if loaded_resource and loaded_resource is Item: # Assuming Item is a class_name for your Item resource
					if not loaded_resource.id.is_empty():
						_loaded_item_resources[loaded_resource.id] = loaded_resource
						print("DEBUG ITEMDATA: Loaded .tres item: ", loaded_resource.id, " from ", full_path, ". Its texture_path: ", loaded_resource.texture_path, ". Attack Bonus: ", loaded_resource.attack_bonus)
						# Register the texture path from the .tres file for lookup later
						register_item_path(loaded_resource.id, loaded_resource.texture_path, "ItemData_tres")
					else:
						print("ItemData WARNING: .tres file '", full_path, "' has an empty id! Skipping this resource.")
				else:
					print("ItemData WARNING: Failed to load valid Item resource from: ", full_path)
			file_name = dir.get_next()
		dir.list_dir_end() # Call list_dir_end after the loop
	else:
		print("ItemData ERROR: Could not open directory for Item resources: ", ITEMS_RESOURCES_DIR, ". Please ensure this path exists and is correct.")


func get_item_by_id(item_id_to_get: String) -> Item:
	# 1. Try to get from loaded .tres resources
	if _loaded_item_resources.has(item_id_to_get):
		var item_from_tres = _loaded_item_resources[item_id_to_get].duplicate()
		_apply_random_stats_if_needed(item_from_tres) # <-- Changed to a more general function
		return item_from_tres
	
	# 2. Try to get from dynamically generated mock items cache
	if _generated_item_cache.has(item_id_to_get):
		return _generated_item_cache[item_id_to_get].duplicate()

	# 3. If not found in loaded .tres or cache, try to create a new mock item from image path
	if _full_paths_map.has(item_id_to_get):
		var mock_item = ITEM_CLASS.new()
		mock_item.id = item_id_to_get
		mock_item.item_name = item_id_to_get.capitalize().replace("_", " ")
		mock_item.texture_path = _full_paths_map[item_id_to_get]
		
		mock_item.rarity = _get_rarity_from_filename_static(item_id_to_get)

		_apply_random_stats_if_needed(mock_item) # <-- Changed to a more general function
		
		_generated_item_cache[item_id_to_get] = mock_item
		print("DEBUG ITEMDATA: Generated mock Item for ID: ", item_id_to_get, " with texture: ", mock_item.texture_path, ", Rarity: ", mock_item.rarity, ", Attack Bonus: ", mock_item.attack_bonus, ", Defense Bonus: ", mock_item.defense_bonus)
		return mock_item.duplicate()
	else:
		print("ItemData ERROR: Item with ID '", item_id_to_get, "' not found in .tres or image paths.")
		return null



func register_item_path(item_id_param: String, path: String, source: String = "Unknown") -> void:
	if not item_id_param.is_empty() and not path.is_empty():
		_full_paths_map[item_id_param] = path
		print("DEBUG ITEMDATA: Registered path: id='", item_id_param, "', path='", path, "' (from ", source, ").")
	else:
		print("ItemData WARNING: Attempted to register empty id or path from ", source, " (ID: '", item_id_param, "', Path: '", path, "').")

# --- MODIFIED HELPER FUNCTION: Apply random stats if needed ---
func _apply_random_stats_if_needed(item: Item) -> void:
	# Ensure item.rarity is set first
	if item.rarity.is_empty() or item.rarity == "default":
		item.rarity = _get_rarity_from_filename_static(item.id)

	# Apply random attack_bonus if not explicitly set (or 0)
	if item.attack_bonus == 0:
		var attack_bonus_range = ATTACK_BONUS_RANGES.get(item.rarity, ATTACK_BONUS_RANGES["common"])
		item.attack_bonus = randi_range(attack_bonus_range.min, attack_bonus_range.max)
		print("DEBUG ITEMDATA: Assigned random attack_bonus (", item.attack_bonus, ") for item ID: ", item.id, " (Rarity: ", item.rarity, ")")

	# NEW: Apply random defense_bonus if not explicitly set (or 0)
	if item.defense_bonus == 0: # Assuming defense_bonus also defaults to 0
		var defense_bonus_range = DEFENSE_BONUS_RANGES.get(item.rarity, DEFENSE_BONUS_RANGES["common"])
		item.defense_bonus = randi_range(defense_bonus_range.min, defense_bonus_range.max)
		print("DEBUG ITEMDATA: Assigned random defense_bonus (", item.defense_bonus, ") for item ID: ", item.id, " (Rarity: ", item.rarity, ")")


# --- NEW HELPER FUNCTION: Extracts rarity from item ID (filename base) ---
# This is a static helper, assuming item_id is derived from a filename like "Icon_rarity_..."
func _get_rarity_from_filename_static(item_id: String) -> String:
	var filename_lower = item_id.to_lower()
	if "_legendary" in filename_lower: return "legendary"
	elif "_epic" in filename_lower: return "epic"
	elif "_rare" in filename_lower: return "rare"
	elif "_common" in filename_lower: return "common"
	return "common" # Default if no rarity keyword found


# --- Your existing _add_item_paths_from_dirs function (ensure it calls register_item_path with correct ID) ---
func _add_item_paths_from_dirs() -> void:
	print("DEBUG: Populating items from asset directories...")
	var asset_dirs = [
		"res://assets/drop-assets/belts/",
		"res://assets/drop-assets/books/",
		"res://assets/drop-assets/guns/",
		# Add any other directories here that contain item images you want to load as generic items
	]

	for dir_path in asset_dirs:
		var dir = DirAccess.open(dir_path)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if file_name.ends_with(".png") or file_name.ends_with(".jpg") or file_name.ends_with(".webp"):
					var full_path = dir_path + file_name
					var item_id_from_filename = file_name.get_basename() # Better way to get filename without extension
					
					# Ensure the Item resource has a 'rarity' property
					# We might need to add a default rarity to the Item resource class or set it here
					# For now, this is primarily registering the path. Rarity will be inferred later.
					register_item_path(item_id_from_filename, full_path, "AssetDirScan")
				file_name = dir.get_next()
			dir.list_dir_end()
		else:
			print("DEBUG ITEMDATA ERROR: Could not open directory: ", dir_path)
