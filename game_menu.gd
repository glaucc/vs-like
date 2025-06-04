# GameMenu.gd
extends Control

@onready var coins_label: Label = %CoinLabel
@onready var defense_label: Label = %DefenseLabel
@onready var attack_label: Label = %AttackDamageLabel

@onready var inventory_grid: GridContainer = %InventoryGrid
@onready var description_label: RichTextLabel = %DescriptionLabel # Ensure this is a RichTextLabel for bold text


@onready var weapon_equip_slot: Control = %WeaponEquipSlot
@onready var armor_equip_slot: Control = %ArmorEquipSlot
@onready var accessory_equip_slot_1: Control = %AccessoryEquipSlot1
@onready var accessory_equip_slot_2: Control = %AccessoryEquipSlot2

# Preload the InventorySlot scene
const INVENTORY_SLOT_SCENE = preload("res://inventory/InventorySlot.tscn") # Adjust path if different

# State variables
var _selected_inventory_item_id: String = "" # Item ID clicked in inventory
var _active_equip_slot_id: String = "" # ID of the equip slot currently selected/awaiting item
var _last_clicked_equip_slot_time: float = 0.0 # To detect double-clicks for unequip
const DOUBLE_CLICK_THRESHOLD: float = 0.3 # Time in seconds for double-click


func _ready() -> void:
	# Ensure Autoload and ItemData are available
	if not has_node("/root/Autoload"):
		print("ERROR: Autoload 'Autoload' not found! Make sure it's in Project Settings -> Autoload.")
		set_process(false)
		return
	if not has_node("/root/ItemData"):
		print("ERROR: Autoload 'ItemData' not found! Make sure it's in Project Settings -> Autoload and spelled correctly.")
		set_process(false)
		return

	# Connect to Autoload's item_added signal to update inventory in real-time
	if Autoload.has_signal("item_added"):
		Autoload.item_added.connect(_on_item_added_to_inventory)
	else:
		print("GameMenu WARNING: Autoload.gd does not have 'item_added' signal. Inventory won't auto-refresh.")

	# Connect signals from equip slot instances
	# IMPORTANT: Ensure your EquipSlot.tscn root node has a 'clicked' signal
	weapon_equip_slot.clicked.connect(_on_equip_slot_clicked)
	armor_equip_slot.clicked.connect(_on_equip_slot_clicked)
	accessory_equip_slot_1.clicked.connect(_on_equip_slot_clicked)
	accessory_equip_slot_2.clicked.connect(_on_equip_slot_clicked)
	
	# Initial population and update
	_populate_inventory() # Initially, no filter
	_update_equip_slots()
	_update_player_stats()
	_clear_selection_details() # Also clears active equip slot


# Call this when an item is added to inventory (e.g., from ChestScene)
func _on_item_added_to_inventory(item_id: String, new_count: int) -> void:
	print("GameMenu: Received item_added signal for ", item_id, ". Refreshing inventory.")
	_populate_inventory(_get_filter_slot_type()) # Refresh with current filter or no filter
	_update_equip_slots() # An equipped item might have been affected (e.g., if you pick up another of the same type)
	_update_player_stats() # Coins or other stats might change


# Populates the inventory grid, optionally filtering by item slot type
func _populate_inventory(filter_slot_type: String = "") -> void:
	# Clear existing slots
	for child in inventory_grid.get_children():
		child.queue_free()

	var player_items = Autoload.get_all_inventory_items() # Get a copy of the inventory
	
	if player_items.is_empty():
		print("GameMenu: Inventory is empty.")
		return

	var sorted_item_ids = player_items.keys()
	sorted_item_ids.sort()

	for item_id in sorted_item_ids:
		var quantity = player_items[item_id]
		var item_resource: Item = ItemData.get_item_by_id(item_id)
		
		# --- ADDED NULL CHECK HERE ---
		if item_resource == null:
			print("GameMenu WARNING: Item resource for ID '", item_id, "' not found (or null). Skipping inventory slot creation.")
			continue # Skip this item if resource is null
		# --- END ADDED NULL CHECK ---

		# Apply filter if provided
		if not filter_slot_type.is_empty() and item_resource.slot_type != filter_slot_type:
			continue # Skip this item if it doesn't match the filter

		# Don't show items that are currently EQUIPPED in any slot, unless it's the item in the current active slot
		var is_equipped_elsewhere = false
		for equipped_slot_id in Autoload.player_equipped_items.keys():
			var equipped_id = Autoload.player_equipped_items[equipped_slot_id]
			if equipped_id == item_id and equipped_slot_id != _active_equip_slot_id: # Don't hide if it's the active slot's item
				is_equipped_elsewhere = true
				break
			
		if is_equipped_elsewhere:
			continue # Skip showing this item in inventory if it's already equipped elsewhere

		var inventory_slot_instance: Control = INVENTORY_SLOT_SCENE.instantiate()
		inventory_grid.add_child(inventory_slot_instance)
		
		inventory_slot_instance.set_item_data(item_resource, quantity)
		
		# Connect the custom 'selected' signal from the InventorySlot
		inventory_slot_instance.selected.connect(_on_inventory_slot_selected)


# Updates the visual display of equipped items in their respective EquipSlot instances
func _update_equip_slots() -> void:
	var equipped_items = Autoload.player_equipped_items # Get a reference to equipped items

	# Pass the correct slot_id and item_id to each EquipSlot instance
	# --- ADDED NULL CHECKS HERE FOR ItemData.get_item_by_id calls ---
	weapon_equip_slot.setup_slot("equip_slot_1", equipped_items.get("equip_slot_1", ""), ItemData.get_item_by_id(equipped_items.get("equip_slot_1", "")))
	armor_equip_slot.setup_slot("equip_slot_2", equipped_items.get("equip_slot_2", ""), ItemData.get_item_by_id(equipped_items.get("equip_slot_2", "")))
	accessory_equip_slot_1.setup_slot("equip_slot_3", equipped_items.get("equip_slot_3", ""), ItemData.get_item_by_id(equipped_items.get("equip_slot_3", "")))
	accessory_equip_slot_2.setup_slot("equip_slot_4", equipped_items.get("equip_slot_4", ""), ItemData.get_item_by_id(equipped_items.get("equip_slot_4", "")))
	# --- END ADDED NULL CHECKS ---

	_update_player_stats() # Update stats after equip slots are updated (bonuses might change)


# Updates player stats based on base stats and equipped items
func _update_player_stats() -> void:
	var total_attack = Autoload.player_base_attack
	var total_defense = Autoload.player_base_defense

	for slot_id in Autoload.player_equipped_items.keys():
		var item_id = Autoload.player_equipped_items[slot_id]
		if item_id: # Check if the item_id is not empty
			var item_resource: Item = ItemData.get_item_by_id(item_id)
			if item_resource: # --- ADDED NULL CHECK HERE ---
				total_attack += item_resource.attack_bonus
				total_defense += item_resource.defense_bonus
			# else: print("GameMenu WARNING: Equipped item '", item_id, "' resource not found for stats calculation.")

	coins_label.text = "Coins: " + str(Autoload.player_coins)
	attack_label.text = "Attack: " + str(total_attack)
	defense_label.text = "Defense: " + str(total_defense)


# Clears selection details and resets active equip slot state
func _clear_selection_details() -> void:
	_selected_inventory_item_id = ""
	_active_equip_slot_id = "" # Reset active equip slot
	_last_clicked_equip_slot_time = 0.0 # Reset double click timer
	_reset_equip_slot_highlights() # Remove highlights from all equip slots
	description_label.text = "Click an equip slot or an inventory item."
	_populate_inventory() # Reset inventory to show all items (no filter)


# Helper to get the item type to filter inventory by, based on active equip slot
func _get_filter_slot_type() -> String:
	if _active_equip_slot_id:
		# Determine the item_type expected by the active equip slot
		match _active_equip_slot_id:
			"equip_slot_1": return "weapon"
			"equip_slot_2": return "armor"
			"equip_slot_3", "equip_slot_4": return "accessory"
			# Add more equip slot IDs and their corresponding item types here
	return "" # No filter


# Helper to reset highlights on all equip slots
func _reset_equip_slot_highlights() -> void:
	weapon_equip_slot.set_highlight(false)
	armor_equip_slot.set_highlight(false)
	accessory_equip_slot_1.set_highlight(false)
	accessory_equip_slot_2.set_highlight(false)
	# Add more calls for other equip slots


# --- Signal Callbacks ---

# Called when any EquipSlot is clicked
func _on_equip_slot_clicked(slot_id: String) -> void:
	print("GameMenu: Equip slot clicked: ", slot_id)

	var current_time = Time.get_ticks_msec() / 1000.0 # Get current time in seconds

	if _active_equip_slot_id == slot_id and (current_time - _last_clicked_equip_slot_time) < DOUBLE_CLICK_THRESHOLD:
		# Double-click detected on the SAME active equip slot - Unequip!
		var equipped_item_id_in_slot = Autoload.player_equipped_items.get(slot_id, "")
		if equipped_item_id_in_slot:
			_unequip_item(slot_id)
			_clear_selection_details() # Clear state after unequip
		else:
			# Double-clicked an empty slot - just clear details
			_clear_selection_details()
		return

	# Single click or different slot clicked
	_clear_selection_details() # Clear any previous inventory selection or active slot state
	_active_equip_slot_id = slot_id # Set the new active equip slot
	_last_clicked_equip_slot_time = current_time # Update last clicked time

	# Highlight the clicked equip slot
	match slot_id:
		"equip_slot_1": weapon_equip_slot.set_highlight(true)
		"equip_slot_2": armor_equip_slot.set_highlight(true)
		"equip_slot_3": accessory_equip_slot_1.set_highlight(true)
		"equip_slot_4": accessory_equip_slot_2.set_highlight(true)
		# Add more cases for additional equip slots

	var equipped_item_id = Autoload.player_equipped_items.get(slot_id, "")
	if equipped_item_id: # Check if item_id is not empty
		# If the slot has an item, show its details
		var item_resource: Item = ItemData.get_item_by_id(equipped_item_id)
		if item_resource: # --- ADDED NULL CHECK HERE ---
			description_label.text = (
				"[b]" + item_resource.item_name + "[/b]\n" +
				"Rarity: " + item_resource.rarity.capitalize() + "\n" +
				"Type: " + item_resource.slot_type.capitalize() + "\n" +
				"Attack Bonus: " + str(item_resource.attack_bonus) + "\n" +
				"Defense Bonus: " + str(item_resource.defense_bonus) + "\n" +
				"Description: " + item_resource.description
			)
		else:
			description_label.text = "Equipped item data not found."
	else:
		# If the slot is empty, show prompt
		description_label.text = "Click an item in inventory to equip to this slot."

	# Filter inventory based on the clicked equip slot's type
	_populate_inventory(_get_filter_slot_type())


# Called when an InventorySlot is clicked
func _on_inventory_slot_selected(item_id: String) -> void:
	_selected_inventory_item_id = item_id
	var item_resource: Item = ItemData.get_item_by_id(item_id)

	if item_resource: # --- ADDED NULL CHECK HERE ---
		description_label.text = (
			"[b]" + item_resource.item_name + "[/b]\n" +
			"Rarity: " + item_resource.rarity.capitalize() + "\n" +
			"Type: " + item_resource.slot_type.capitalize() + "\n" +
			"Attack Bonus: " + str(item_resource.attack_bonus) + "\n" +
			"Defense Bonus: " + str(item_resource.defense_bonus) + "\n" +
			"Description: " + item_resource.description
		)

		# If an equip slot is active, attempt to equip/swap
		if _active_equip_slot_id:
			var compatible_slot_type = _get_filter_slot_type()
			if item_resource.slot_type == compatible_slot_type:
				# This is a direct equip/swap action
				_equip_item(item_id, _active_equip_slot_id)
				_clear_selection_details() # Clear state after equipping/swapping
			else:
				print("GameMenu: Selected inventory item '", item_id, "' is not compatible with active equip slot '", _active_equip_slot_id, "'.")
				# Just show details, don't equip if not compatible
		else:
			# No equip slot is active, just show details of the inventory item
			print("GameMenu: No equip slot active. Just showing details for ", item_id)
	else:
		_clear_selection_details()
		print("GameMenu ERROR: Selected inventory item resource not found for ID: ", item_id)


# Helper function to handle equipping an item
func _equip_item(item_id_to_equip: String, target_slot_id: String) -> void:
	# 1. Check if an item is already in the target slot (for swapping)
	var currently_equipped_item_id = Autoload.player_equipped_items.get(target_slot_id, "")
	if currently_equipped_item_id and not currently_equipped_item_id.is_empty():
		# If there's an item, move it back to inventory
		var equipped_item_resource: Item = ItemData.get_item_by_id(currently_equipped_item_id)
		if equipped_item_resource: # --- ADDED NULL CHECK HERE ---
			Autoload.add_item_to_inventory(currently_equipped_item_id, 1)
			print("GameMenu: Unequipped ", currently_equipped_item_id, " from ", target_slot_id, " and moved back to inventory.")
		else:
			print("GameMenu WARNING: Equipped item '", currently_equipped_item_id, "' resource not found during re-inventory.")

	# 2. Equip the new item
	if Autoload.remove_item_from_inventory(item_id_to_equip, 1):
		Autoload.player_equipped_items[target_slot_id] = item_id_to_equip
		print("GameMenu: Equipped ", item_id_to_equip, " into ", target_slot_id)
		Autoload.save_all_player_data()
		
		_update_equip_slots() # Update visual for equip slot
		_populate_inventory(_get_filter_slot_type()) # Re-populate inventory with current filter
		_update_player_stats()
	else:
		print("GameMenu ERROR: Could not remove item '", item_id_to_equip, "' from inventory to equip. Is it actually in inventory?")


# Helper function to handle unequipping an item
func _unequip_item(slot_id_to_unequip: String) -> void:
	var item_id_to_unequip = Autoload.player_equipped_items.get(slot_id_to_unequip, "")
	if item_id_to_unequip.is_empty(): # Changed from 'not item_id_to_unequip or item_id_to_unequip == ""'
		print("GameMenu: Slot ", slot_id_to_unequip, " is already empty or has no item.")
		return

	# Add the item back to inventory
	Autoload.add_item_to_inventory(item_id_to_unequip, 1)

	# Clear the equip slot
	Autoload.player_equipped_items[slot_id_to_unequip] = ""
	print("GameMenu: Unequipped ", item_id_to_unequip, " from ", slot_id_to_unequip, " and moved to inventory.")
	Autoload.save_all_player_data()

	_update_equip_slots() # Update visual for equip slot
	_populate_inventory(_get_filter_slot_type()) # Re-populate inventory with current filter
	_update_player_stats()



func _on_shop_button_pressed() -> void:
	var shop = load("res://shop.tscn")
	print("Loaded scene path:", shop.resource_path)
	get_tree().change_scene_to_packed(shop)
