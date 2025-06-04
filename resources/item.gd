# res://resources/item.gd
extends Resource
class_name Item # This allows you to create new 'Item' resources directly in the editor

@export var id: String = "" # A unique identifier for this item (e.g., "common_sword")
@export var item_name: String = "New Item" # The display name of the item
@export_file("*.png", "*.webp", "*.jpg") var texture_path: String = "" # Path to the item's visual texture
@export var rarity: String = "common" # Rarity string (e.g., "common", "rare", "epic", "legendary")

# --- NEW: Item Stats ---
@export var attack_bonus: int = 0
@export var defense_bonus: int = 0
# You can add more stats here as needed, e.g., hp_bonus, speed_bonus, etc.

# A simple constructor for creating items programmatically if needed
func _init(p_id: String = "", p_name: String = "New Item", p_texture_path: String = "", p_rarity: String = "common", p_attack_bonus: int = 0, p_defense_bonus: int = 0):
	id = p_id
	item_name = p_name
	texture_path = p_texture_path
	rarity = p_rarity
	attack_bonus = p_attack_bonus
	defense_bonus = p_defense_bonus

# Helper function to easily load the texture from its path
func get_texture() -> Texture2D:
	if texture_path.is_empty():
		return null # Or return a default 'missing texture' here
	return load(texture_path)
