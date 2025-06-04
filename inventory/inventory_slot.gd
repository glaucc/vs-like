# InventorySlot.gd
extends Control

@onready var item_icon: TextureRect = %ItemIcon
@onready var quantity_label: Label = %QuantityLabel
@onready var clickable_area: Button = %ClickableArea

var item_id: String = "" # Stores the ID of the item this slot represents

# Signal emitted when this slot is clicked
signal selected(item_id: String)


# Sets the item data for this slot
func set_item_data(item_resource: Item, quantity: int) -> void:
	if item_resource:
		self.item_id = item_resource.id
		item_icon.texture = load(item_resource.texture_path)
		quantity_label.text = str(quantity)
		item_icon.show()
		quantity_label.show()
		# You might also want to set a tooltip or some other visual indicator
		# based on rarity (e.g., background.modulate)
	else:
		# Clear the slot if no item
		self.item_id = ""
		item_icon.texture = null
		quantity_label.text = ""
		item_icon.hide()
		quantity_label.hide()

func _on_clickable_area_pressed() -> void:
	if item_id: # Only emit if there's an actual item in the slot
		selected.emit(item_id)
		print("InventorySlot: Selected item ID: ", item_id)
