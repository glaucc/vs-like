# res://ui/item_selection_popup.gd
extends PanelContainer
class_name ItemSelectionPopup # <--- ADD THIS LINE: Define a class name for easier type-hinting

@onready var items_grid: GridContainer = %ItemsGrid
@onready var close_button: Button = %CloseButton
@onready var animation_player: AnimationPlayer = %AnimationPlayer # <--- ADD THIS LINE
# @onready var item_selection_popup: PanelContainer = $"." # This is redundant, `self` refers to the node itself

const INVENTORY_SLOT_SCENE = preload("res://inventory/InventorySlot.tscn")

signal item_selected(selected_item_id: String, target_equip_slot_id: String)

var _target_equip_slot_id: String = ""

func _ready() -> void:
	# IMPORTANT: Do NOT play the animation here if you want it to play every time the popup is shown.
	# The 'play_fade_in_animation()' function will be called externally when needed.
	# %AnimationPlayer.play("fade-in") # <-- REMOVE OR COMMENT OUT THIS LINE

	# Connect the close button signal - good to have this in _ready
	close_button.pressed.connect(_on_close_button_pressed)
	
	# It's good practice to hide the popup initially if it's part of a scene
	# that's always in the tree but only sometimes visible.
	# However, since you're instantiating it, it will start hidden by default
	# until you call show(). So, $".".hide() here might be redundant depending on usage.
	# If your popup is part of the main GameMenu scene from the start, then uncomment this.
	# self.hide() # Or $".".hide() is equivalent to self.hide() for the root of the script


# NEW FUNCTION: To explicitly play the fade-in animation
func play_fade_in_animation() -> void:
	if animation_player:
		animation_player.play("fade-in") # Ensure "fade-in" is the exact name of your animation
	else:
		print("ItemSelectionPopup WARNING: AnimationPlayer not found or not ready.")

func populate_items(inventory_data: Dictionary, target_slot_id: String) -> void:
	_target_equip_slot_id = target_slot_id

	print("DEBUG POPUP: populate_items called for slot '", target_slot_id, "'")
	print("DEBUG POPUP: Incoming inventory_data: ", inventory_data)

	for child in items_grid.get_children():
		child.queue_free()
	
	print("DEBUG POPUP: items_grid children after clearing: ", items_grid.get_child_count())

	var none_slot_instance: Control = INVENTORY_SLOT_SCENE.instantiate()
	items_grid.add_child(none_slot_instance)
	none_slot_instance.set_item_data(null, 0)
	none_slot_instance.selected.connect(_on_inventory_slot_clicked)

	print("DEBUG POPUP: 'None' slot added. items_grid children: ", items_grid.get_child_count())

	for item_id_key in inventory_data.keys():
		var quantity = inventory_data[item_id_key]
		var item_resource = ItemData.get_item_by_id(item_id_key)

		if item_resource:
			print("DEBUG POPUP: Found ItemData for ID: ", item_id_key, ". Name: ", item_resource.item_name)
			var inventory_slot_instance: Control = INVENTORY_SLOT_SCENE.instantiate()
			items_grid.add_child(inventory_slot_instance)
			inventory_slot_instance.set_item_data(item_resource, quantity)
			inventory_slot_instance.selected.connect(_on_inventory_slot_clicked)
			print("DEBUG POPUP: Added InventorySlot instance for '", item_id_key, "'. Grid children: ", items_grid.get_child_count())
		else:
			print("ItemSelectionPopup WARNING: Could not find ItemData for ID: ", item_id_key)

	self.show() # <--- Changed $"." to self for consistency

	print("DEBUG POPUP: Final items_grid children count: ", items_grid.get_child_count())

	# Your manual centering logic. Ensure it works as intended.
	var viewport_size = get_viewport_rect().size
	var popup_size = self.size

	var new_position = (viewport_size - popup_size) / 2
	new_position.x += 650
	new_position.y -= 100
	
	self.global_position = new_position
	print("ItemSelectionPopup: Final Global Position: ", self.global_position)
	
	# get_tree().paused = true # Handle pausing in GameMenu or ensure it's unpaused when closing

func _on_inventory_slot_clicked(clicked_item_id: String) -> void:
	item_selected.emit(clicked_item_id, _target_equip_slot_id)
	print("ItemSelectionPopup: Item '", clicked_item_id, "' selected for slot '", _target_equip_slot_id, "'")
	hide()
	# get_tree().paused = false # Handle pausing in GameMenu or ensure it's unpaused when closing


func _on_close_button_pressed() -> void:
	print("ItemSelectionPopup: Close button pressed.")
	self.hide() # <--- Changed item_selection_popup.hide() to self.hide() for consistency
	# get_tree().paused = false # Handle pausing in GameMenu or ensure it's unpaused when closing
