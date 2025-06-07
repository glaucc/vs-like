# InventorySlot.gd
extends Control

@onready var item_icon: TextureRect = %ItemIcon
@onready var quantity_label: Label = %QuantityLabel
@onready var clickable_area: Button = %ClickableArea
@onready var highlight_background: ColorRect = %HighlightBackground

var item_id: String = "" 

signal selected(item_id: String)

const PLACEHOLDER_SCENE: PackedScene = preload("res://cross_mark.tscn")

const HOVER_SCALE_AMOUNT = 1.05
const HOVER_ANIM_DURATION = 0.15

var original_scale: Vector2

# --- NEW: Member variables to hold Tween references ---
var _icon_tween: Tween = null
var _hover_tween: Tween = null


func _ready() -> void:
	original_scale = scale
	
	set_process_input(true)
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func set_item_data(item_resource: Item, quantity: int) -> void:
	print("DEBUG INVENTORYSLOT: set_item_data called for item_resource: ", item_resource, ", quantity: ", quantity)
	
	for child in item_icon.get_children():
		if child is Control and child.name == "CrossMarkPlaceholder":
			child.queue_free()

	if quantity > 0:
		if quantity_label:
			quantity_label.text = str(quantity)
			quantity_label.show()
	else:
		if quantity_label:
			quantity_label.hide()

	# --- NEW: Kill previous icon tween if it exists and is valid ---
	if _icon_tween and _icon_tween.is_valid():
		_icon_tween.kill()
	item_icon.scale = Vector2(1,1) # Reset to default before new tween
	item_icon.modulate = Color(1,1,1,1) # Reset to default before new tween

	if item_resource != null and not item_resource.texture_path.is_empty():
		var loaded_texture: Texture2D = load(item_resource.texture_path)
		if loaded_texture:
			item_icon.texture = loaded_texture
			item_icon.show()

			_icon_tween = get_tree().create_tween() # Store the tween reference
			_icon_tween.bind_node(item_icon) # Binding to item_icon for cleanup
			
			item_icon.scale = Vector2(0.0, 0.0)
			item_icon.modulate = Color(1, 1, 1, 0)
			
			_icon_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			_icon_tween.set_parallel(true)
			_icon_tween.tween_property(item_icon, "scale", Vector2(1.0, 1.0), 0.3)
			_icon_tween.tween_property(item_icon, "modulate", Color(1, 1, 1, 1), 0.2)
		else:
			print("InventorySlot WARNING: Could not load texture from path: ", item_resource.texture_path, ". Using placeholder scene.")
			item_icon.texture = null
			_add_placeholder_scene()
			item_icon.show()

		self.item_id = item_resource.id

	else:
		print("InventorySlot: No item resource or empty texture path (This is for the 'None' slot). Using placeholder scene.")
		
		if item_icon.texture != null || item_icon.get_children().size() > 0:
			_icon_tween = get_tree().create_tween() # Store the tween reference
			_icon_tween.bind_node(item_icon) # Binding to item_icon for cleanup
			
			_icon_tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
			_icon_tween.tween_property(item_icon, "modulate", Color(1, 1, 1, 0), 0.2)
			_icon_tween.tween_callback(func():
				item_icon.texture = null
				_add_placeholder_scene()
				item_icon.show()
				item_icon.modulate = Color(1,1,1,1)
			)
		else:
			item_icon.texture = null
			_add_placeholder_scene()
			item_icon.show()

		self.item_id = ""

	print("DEBUG INVENTORYSLOT: item_icon.texture set to: ", item_icon.texture, ", item_icon.visible: ", item_icon.visible)


func _add_placeholder_scene() -> void:
	if PLACEHOLDER_SCENE:
		if item_icon.get_node_or_null("CrossMarkPlaceholder"):
			return
		
		var placeholder_instance = PLACEHOLDER_SCENE.instantiate()
		item_icon.add_child(placeholder_instance)
		placeholder_instance.name = "CrossMarkPlaceholder"
		if placeholder_instance is Control:
			placeholder_instance.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			placeholder_instance.mouse_filter = Control.MOUSE_FILTER_IGNORE
		elif placeholder_instance is Node2D:
			placeholder_instance.position = Vector2(47, 60)
	else:
		print("InventorySlot ERROR: PLACEHOLDER_SCENE is null or not loaded.")


func _on_clickable_area_pressed() -> void:
	if item_id:
		selected.emit(item_id)
		print("InventorySlot: Clicked on item ID: ", item_id)
	else:
		selected.emit("")
		print("InventorySlot: Clicked on 'None' slot (item ID: empty string).")

func _on_mouse_entered() -> void:
	# --- NEW: Kill previous hover tween if it exists and is valid ---
	if _hover_tween and _hover_tween.is_valid():
		_hover_tween.kill()
	
	_hover_tween = get_tree().create_tween() # Store the tween reference
	_hover_tween.bind_node(self) # Binding to self for cleanup
	
	_hover_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_hover_tween.tween_property(self, "scale", original_scale * HOVER_SCALE_AMOUNT, HOVER_ANIM_DURATION)

func _on_mouse_exited() -> void:
	# --- NEW: Kill previous hover tween if it exists and is valid ---
	if _hover_tween and _hover_tween.is_valid():
		_hover_tween.kill()
		
	_hover_tween = get_tree().create_tween() # Store the tween reference
	_hover_tween.bind_node(self) # Binding to self for cleanup
	
	_hover_tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	_hover_tween.tween_property(self, "scale", original_scale, HOVER_ANIM_DURATION)
