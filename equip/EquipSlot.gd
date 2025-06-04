# EquipSlot.gd
extends Control

@onready var item_icon: TextureRect = %ItemIcon
@onready var slot_name_label: Label = %SlotNameLabel
@onready var highlight_background: ColorRect = %HighlightBackground
@onready var clickable_area: Button = %Button # Make sure this matches your Button node name in scene!

var equip_slot_id: String = "" # e.g., "equip_slot_1", "equip_slot_2"
var current_item_id: String = "" # ID of the item currently equipped here

# Signal emitted when this equip slot is clicked
signal clicked(slot_id: String)

func _ready() -> void:
	set_highlight(false) # Start with no highlight

# Call this to set up the equip slot's display
func setup_slot(p_equip_slot_id: String, p_item_id: String, item_resource: Item = null) -> void:
	equip_slot_id = p_equip_slot_id
	current_item_id = p_item_id
	slot_name_label.text = _get_display_name_for_slot_id(p_equip_slot_id)

	if current_item_id and item_resource:
		item_icon.texture = load(item_resource.texture_path)
		item_icon.show()
	else:
		item_icon.texture = null
		item_icon.hide()

# Helper to convert internal ID to display name (customize as needed)
func _get_display_name_for_slot_id(id: String) -> String:
	match id:
		"equip_slot_1": return "Weapon"
		"equip_slot_2": return "Armor"
		"equip_slot_3": return "Acc. 1"
		"equip_slot_4": return "Acc. 2"
		_: return id.capitalize().replace("_", " ")

# Toggles the visual highlight of the slot
func set_highlight(active: bool) -> void:
	highlight_background.visible = active

# --- Signal Callback for the Button ---
func _on_clickable_area_pressed() -> void:
	clicked.emit(equip_slot_id)
	print("EquipSlot: Clicked on ", equip_slot_id, ". Current item: ", current_item_id)
