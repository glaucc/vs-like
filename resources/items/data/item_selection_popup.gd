# res://ui/item_selection_popup.gd
extends PanelContainer

@onready var items_grid: GridContainer = %ItemsGrid
@onready var close_button: Button = %CloseButton
@onready var item_selection_popup: PanelContainer = $"."

const INVENTORY_SLOT_SCENE = preload("res://inventory/InventorySlot.tscn")

signal item_selected(selected_item_id: String, target_equip_slot_id: String)

var _target_equip_slot_id: String = ""

func _ready() -> void:
	# close_button.pressed.connect(_on_close_button_pressed) # Ensure this is connected in editor or here
	$".".hide() # Start hidden

func populate_items(inventory_data: Dictionary, target_slot_id: String) -> void:
	_target_equip_slot_id = target_slot_id

	# --- NEW DEBUG PRINT: Check incoming inventory data ---
	print("DEBUG POPUP: populate_items called for slot '", target_slot_id, "'")
	print("DEBUG POPUP: Incoming inventory_data: ", inventory_data)
	# --- END NEW DEBUG PRINT ---

	# Clear existing slots
	for child in items_grid.get_children():
		child.queue_free()
	
	# --- NEW DEBUG PRINT: Confirm grid is cleared ---
	print("DEBUG POPUP: items_grid children after clearing: ", items_grid.get_child_count())
	# --- END NEW DEBUG PRINT ---

	# Add a "None" slot first, to allow unequipping
	var none_slot_instance: Control = INVENTORY_SLOT_SCENE.instantiate()
	items_grid.add_child(none_slot_instance)
	none_slot_instance.set_item_data(null, 0)
	none_slot_instance.selected.connect(_on_inventory_slot_clicked)

	# --- NEW DEBUG PRINT: Confirm None slot added ---
	print("DEBUG POPUP: 'None' slot added. items_grid children: ", items_grid.get_child_count())
	# --- END NEW DEBUG PRINT ---

	# Populate with actual inventory items
	for item_id_key in inventory_data.keys():
		var quantity = inventory_data[item_id_key]
		var item_resource = ItemData.get_item_by_id(item_id_key)

		# --- NEW DEBUG PRINT: Check if item_resource is found ---
		if item_resource:
			print("DEBUG POPUP: Found ItemData for ID: ", item_id_key, ". Name: ", item_resource.item_name)
			# --- END NEW DEBUG PRINT ---

			var inventory_slot_instance: Control = INVENTORY_SLOT_SCENE.instantiate()
			items_grid.add_child(inventory_slot_instance)
			inventory_slot_instance.set_item_data(item_resource, quantity)
			inventory_slot_instance.selected.connect(_on_inventory_slot_clicked)

			# --- NEW DEBUG PRINT: Confirm item slot added ---
			print("DEBUG POPUP: Added InventorySlot instance for '", item_id_key, "'. Grid children: ", items_grid.get_child_count())
			# --- END NEW DEBUG PRINT ---
		else:
			print("ItemSelectionPopup WARNING: Could not find ItemData for ID: ", item_id_key)

	# Show the popup
	$".".show()
	
	# --- NEW DEBUG PRINT: Final check of grid children before positioning ---
	print("DEBUG POPUP: Final items_grid children count: ", items_grid.get_child_count())
	# --- END NEW DEBUG PRINT ---

	# --- MANUAL CENTERING USING GLOBAL_POSITION ---
	var viewport_size = get_viewport_rect().size
	var popup_size = self.size

	var new_position = (viewport_size - popup_size) / 2
	new_position.x += 650
	new_position.y -= 100
	
	self.global_position = new_position
	print("ItemSelectionPopup: Final Global Position: ", self.global_position)
	# --- END MANUAL CENTERING ---
	
	# get_tree().paused = true


func _on_inventory_slot_clicked(clicked_item_id: String) -> void:
	item_selected.emit(clicked_item_id, _target_equip_slot_id)
	print("ItemSelectionPopup: Item '", clicked_item_id, "' selected for slot '", _target_equip_slot_id, "'")
	hide()
	# get_tree().paused = false


func _on_close_button_pressed() -> void:
	print("ItemSelectionPopup: Close button pressed.")
	item_selection_popup.hide()
	# get_tree().paused = false
