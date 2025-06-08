# res://ui/GameMenu.gd
extends Control

@onready var equip_slot_1: Control = %WeaponEquipSlot
@onready var equip_slot_2: Control = %ArmorEquipSlot
@onready var equip_slot_3: Control = %AccessoryEquipSlot1
@onready var equip_slot_4: Control = %AccessoryEquipSlot2

@onready var defense_label: Label = %DefenseLabel
@onready var attack_damage_label: Label = %AttackDamageLabel


# --- Preloaded Scenes ---
const INVENTORY_SLOT_SCENE = preload("res://inventory/InventorySlot.tscn")
const ITEM_SELECTION_POPUP_SCENE = preload("res://resources/items/data/item_selection_popup.tscn")

# Change type to ItemSelectionPopup after adding 'class_name' in popup script
var _item_selection_popup_instance: ItemSelectionPopup = null # <--- IMPORTANT: Changed type hint here

func _ready() -> void:
	print("GameMenu: _ready called.")

	equip_slot_1.equip_slot_id = "equip_slot_1"
	equip_slot_2.equip_slot_id = "equip_slot_2"
	equip_slot_3.equip_slot_id = "equip_slot_3"
	equip_slot_4.equip_slot_id = "equip_slot_4"

	equip_slot_1.clicked.connect(_on_equip_slot_clicked)
	equip_slot_2.clicked.connect(_on_equip_slot_clicked)
	equip_slot_3.clicked.connect(_on_equip_slot_clicked)
	equip_slot_4.clicked.connect(_on_equip_slot_clicked)

	_update_all_equip_slots_display()
	_update_player_stats_display()
	
	%ui_anims.play("menu-idle")


func _on_equip_slot_clicked(slot_id: String) -> void:
	print("GameMenu: Equip slot '", slot_id, "' clicked. Attempting to open item selection popup.")

	if _item_selection_popup_instance == null:
		print("GameMenu: Popup instance is null. Instantiating ItemSelectionPopup scene.")
		_item_selection_popup_instance = ITEM_SELECTION_POPUP_SCENE.instantiate()
		add_child(_item_selection_popup_instance) # Add it to the tree first

		print("DEBUG POPUP: Initial popup position after add_child (before await): ", _item_selection_popup_instance.position)

		await get_tree().process_frame # Wait a frame
		print("DEBUG POPUP: Popup position AFTER await process_frame: ", _item_selection_popup_instance.position)
		
		var viewport_size = get_viewport_rect().size
		var popup_size = _item_selection_popup_instance.size
		print("DEBUG POPUP: Viewport Size: ", viewport_size)
		print("DEBUG POPUP: Popup Size AFTER await: ", popup_size)
		
		var centered_x = (viewport_size.x / 2.0) - (popup_size.x / 2.0)
		var centered_y = (viewport_size.y / 2.0) - (popup_size.y / 2.0)
		print("DEBUG POPUP: Calculated Centered X: ", centered_x, ", Centered Y: ", centered_y)
		
		var upward_offset = 50
		var final_pos = Vector2(centered_x, centered_y - upward_offset)
		print("DEBUG POPUP: Final calculated position (with offset): ", final_pos)
		
		_item_selection_popup_instance.position = final_pos
		print("DEBUG POPUP: Popup position AFTER assignment: ", _item_selection_popup_instance.position)
		print("DEBUG POPUP: Popup Global Position AFTER assignment: ", _item_selection_popup_instance.global_position)
		
		print("GameMenu: Connecting item_selected signal.")
		_item_selection_popup_instance.item_selected.connect(_on_item_selected_from_popup)
	else:
		print("GameMenu: Popup instance already exists. Showing existing popup.")
		_item_selection_popup_instance.show()
		print("DEBUG POPUP: Existing popup position (on show): ", _item_selection_popup_instance.position)
		print("DEBUG POPUP: Existing popup global position (on show): ", _item_selection_popup_instance.global_position)

	# --- CALL THE ANIMATION PLAY FUNCTION HERE ---
	_item_selection_popup_instance.play_fade_in_animation() # <--- THIS IS THE KEY LINE

	print("GameMenu: Populating popup with inventory data for slot: ", slot_id)
	_item_selection_popup_instance.populate_items(Autoload.player_inventory, slot_id)


func _on_item_selected_from_popup(selected_id: String, target_equip_slot_id: String) -> void:
	print("GameMenu: Pop-up returned item '", selected_id, "' for equip slot '", target_equip_slot_id, "'")

	Autoload.equip_item(target_equip_slot_id, selected_id)

	_update_equip_slot_display(target_equip_slot_id)
	_update_player_stats_display()


func _update_equip_slot_display(slot_id: String) -> void:
	var equip_slot_node: Control = null
	match slot_id:
		"equip_slot_1": equip_slot_node = equip_slot_1
		"equip_slot_2": equip_slot_node = equip_slot_2
		"equip_slot_3": equip_slot_node = equip_slot_3
		"equip_slot_4": equip_slot_node = equip_slot_4
		_:
			print("GameMenu ERROR: Unknown equip slot ID in _update_equip_slot_display: ", slot_id)
			return

	var equipped_id = Autoload.get_equipped_item_id(slot_id)
	var equipped_item_resource: Item = null

	if not equipped_id.is_empty():
		equipped_item_resource = ItemData.get_item_by_id(equipped_id)

	equip_slot_node.setup_slot(slot_id, equipped_id, equipped_item_resource)


func _update_all_equip_slots_display() -> void:
	_update_equip_slot_display("equip_slot_1")
	_update_equip_slot_display("equip_slot_2")
	_update_equip_slot_display("equip_slot_3")
	_update_equip_slot_display("equip_slot_4")


func _update_player_stats_display() -> void:
	var total_attack_bonus: int = 0
	var total_defense_bonus: int = 0

	var equipped_items_dict = Autoload.get_all_equipped_items()

	for slot_id in equipped_items_dict:
		var item_id = equipped_items_dict[slot_id]
		if not item_id.is_empty():
			var item_resource: Item = ItemData.get_item_by_id(item_id)
			if item_resource:
				total_attack_bonus += item_resource.attack_bonus
				total_defense_bonus += item_resource.defense_bonus
			else:
				print("GameMenu WARNING: Could not retrieve Item resource for equipped item ID: ", item_id, " in slot: ", slot_id)

	attack_damage_label.text = str(total_attack_bonus)
	defense_label.text = str(total_defense_bonus)
	print("GameMenu: Total Attack: ", total_attack_bonus, ", Total Defense: ", total_defense_bonus)


func _on_shop_button_pressed() -> void:
	var shop = load("res://shop.tscn")
	print("Loaded scene path:", shop.resource_path)
	get_tree().change_scene_to_packed(shop)


func _on_play_button_pressed() -> void:
	var main_map = load("res://main_map.tscn")
	print("Loaded scene path:", main_map.resource_path)
	get_tree().change_scene_to_packed(main_map)


func _on_left_button_pressed() -> void:
	%AnimationPlayer.play("soon-text")


func _on_right_button_pressed() -> void:
	%AnimationPlayer.play("soon-text")
