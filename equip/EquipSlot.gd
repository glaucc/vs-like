# EquipSlot.gd
extends Control

@onready var item_icon: TextureRect = %ItemIcon
@onready var slot_name_label: Label = %SlotNameLabel
@onready var highlight_background: ColorRect = %HighlightBackground
@onready var clickable_area: Button = %ClickableArea

@onready var equip_particles: CPUParticles2D = %EquipParticles
@onready var rarity_particles: CPUParticles2D = %RarityParticles
@onready var equip_sound_player: AudioStreamPlayer2D = %EquipSoundPlayer

var equip_slot_id: String = ""
var current_item_id: String = ""

signal clicked(equip_slot_id: String)

const PLACEHOLDER_TEXTURE: Texture2D = preload("res://assets/Arrow.png")

const HOVER_SCALE_AMOUNT = 1.05
const HOVER_ANIM_DURATION = 0.15

var original_scale: Vector2
var original_position: Vector2 # Stores the original position of the EquipSlot itself

# --- Member variables to hold Tween references ---
var _icon_tween: Tween = null
var _hover_tween: Tween = null
var _shake_tween: Tween = null


func _ready() -> void:
	original_scale = scale
	# For dynamically generated nodes within containers, the position in _ready()
	# might not be final. setup_slot will handle the definitive position capture.
	original_position = position 
	
	print("DEBUG (EquipSlot:", name, "): _ready() called.")
	print("DEBUG (EquipSlot:", name, "): Initial position (relative to parent): ", position)
	print("DEBUG (EquipSlot:", name, "): Initial global_position: ", global_position)
	print("DEBUG (EquipSlot:", name, "): ItemIcon initial position (relative to EquipSlot): ", item_icon.position)
	
	set_process_input(true)
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	if Autoload: # Check if the Autoload is available
		Autoload.item_equipped_to_slot.connect(_on_item_equipped_from_global)
		print("DEBUG (EquipSlot:", name, "): Connected to Autoload.item_equipped_to_slot signal.")
	else:
		print("ERROR (EquipSlot:", name, "): Autoload script not found! Cannot connect equip signal.")

	if equip_particles:
		equip_particles.emitting = false
	if rarity_particles:
		rarity_particles.emitting = false


func setup_slot(slot_id_param: String, item_id_param: String, item_resource: Item = null) -> void:
	self.equip_slot_id = slot_id_param
	self.current_item_id = item_id_param

	# --- NEW: Wait a frame for the layout system to settle ---
	# This is crucial for dynamically added UI elements within containers.
	# It ensures the 'position' property has been fully calculated by the layout system.
	# await get_tree().create_timer(0.05).timeout # Option 1: Wait for 0.05 seconds
	await get_tree().process_frame # Option 2: Wait for the next process frame (usually better for UI layout)
	print("DEBUG (EquipSlot:", name, "): setup_slot() - Waited a frame. Current position AFTER layout: ", position)

	# --- THE CRITICAL FIX: Update original_position here ---
	# This ensures original_position always holds the *current stable position*
	# of the EquipSlot when it's being displayed or has an item equipped.
	original_position = position 
	print("DEBUG (EquipSlot:", name, "): setup_slot() called. Re-setting original_position to current position: ", original_position)
	
	slot_name_label.text = _get_display_name_for_slot_id(slot_id_param)

	# Kill previous icon tween if it exists and is valid
	if _icon_tween and _icon_tween.is_valid():
		_icon_tween.kill()
	item_icon.scale = Vector2(1,1) # Reset to default before new tween
	item_icon.modulate = Color(1,1,1,1) # Reset to default before new tween


	if item_resource != null and not item_resource.texture_path.is_empty():
		print("EquipSlot: Loading texture for slot '", slot_id_param, "' (item: ", item_resource.id, "): ", item_resource.texture_path)
		var texture: Texture2D = load(item_resource.texture_path)
		if texture:
			item_icon.texture = texture
			item_icon.show()
			
			_icon_tween = get_tree().create_tween() # Store the tween reference
			_icon_tween.bind_node(item_icon) # Binding to item_icon for cleanup
			
			item_icon.scale = Vector2(0.0, 0.0) # Icon starts scaled down for animation
			item_icon.modulate = Color(1, 1, 1, 0) # Icon starts transparent for animation
			
			_icon_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			_icon_tween.set_parallel(true)
			_icon_tween.tween_property(item_icon, "scale", Vector2(1.0, 1.0), 0.3)
			_icon_tween.tween_property(item_icon, "modulate", Color(1, 1, 1, 1), 0.2)
			print("DEBUG (EquipSlot:", name, "): ItemIcon position AFTER setup tween (should be same unless layout changes): ", item_icon.position)
		else:
			print("EquipSlot ERROR: Could not load texture from path: ", item_resource.texture_path, " for item ID: ", item_resource.id)
			item_icon.texture = null
			item_icon.hide()
	else: # If item_resource is null or texture_path is empty (unequipping)
		if item_icon.texture != null: # If there was a texture before
			_icon_tween = get_tree().create_tween() # Store the tween reference
			_icon_tween.bind_node(item_icon) # Binding to item_icon for cleanup
			
			_icon_tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
			_icon_tween.tween_property(item_icon, "modulate", Color(1, 1, 1, 0), 0.2)
			_icon_tween.tween_callback(func():
				item_icon.texture = null
				item_icon.hide()
				item_icon.modulate = Color(1,1,1,1) # Reset modulate for next use
			)
		else: # If no texture was there anyway
			item_icon.texture = null
			item_icon.hide()
			item_icon.modulate = Color(1,1,1,1)


	if rarity_particles:
		rarity_particles.emitting = false
		if item_resource:
			rarity_particles.position = item_icon.position + item_icon.size / 2.0
			
			match item_resource.rarity:
				"rare":
					rarity_particles.color = Color("87ceeb") # Sky Blue
					rarity_particles.emitting = true
				"epic":
					rarity_particles.color = Color("b500ff") # Purple
					rarity_particles.emitting = true
				"legendary":
					rarity_particles.color = Color("ffd700") # Gold
					rarity_particles.emitting = true
				"common":
					rarity_particles.color = Color("a0a0a0") # Greyish
					rarity_particles.emitting = false # Or true for a very subtle effect
				_:
					rarity_particles.emitting = false
		else:
			rarity_particles.emitting = false


func _on_item_equipped_from_global(slot_id: String, item_id: String) -> void:
	# This EquipSlot instance only cares about events for its own slot_id
	if self.equip_slot_id == slot_id:
		print("DEBUG (EquipSlot:", name, "): _on_item_equipped_from_global() received signal for THIS slot (", slot_id, ").")
		play_equip_impact_vfx()
	else:
		print("DEBUG (EquipSlot:", name, "): _on_item_equipped_from_global() received signal for OTHER slot (", slot_id, "). My slot: ", self.equip_slot_id)


func _get_display_name_for_slot_id(id: String) -> String:
	match id:
		"equip_slot_1": return "Weapon"
		"equip_slot_2": return "Armor"
		"equip_slot_3": return "Acc. 1"
		"equip_slot_4": return "Acc. 2"
		_: return id.capitalize().replace("_", " ")

func set_highlight(active: bool) -> void:
	highlight_background.visible = active

func _on_clickable_area_pressed() -> void:
	clicked.emit(equip_slot_id)
	print("EquipSlot: Clicked on ", equip_slot_id, ". Current item: ", current_item_id)

func _on_mouse_entered() -> void:
	print("DEBUG (EquipSlot:", name, "): _on_mouse_entered() called.")
	print("DEBUG (EquipSlot:", name, "): Current position on hover: ", position)
	print("DEBUG (EquipSlot:", name, "): Current scale on hover: ", scale)

	# Kill previous hover tween if it exists and is valid
	if _hover_tween and _hover_tween.is_valid():
		_hover_tween.kill()
	
	_hover_tween = get_tree().create_tween() # Store the tween reference
	_hover_tween.bind_node(self) # Binding to self for cleanup
	
	_hover_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_hover_tween.tween_property(self, "scale", original_scale * HOVER_SCALE_AMOUNT, HOVER_ANIM_DURATION)

func _on_mouse_exited() -> void:
	print("DEBUG (EquipSlot:", name, "): _on_mouse_exited() called.")

	# Kill previous hover tween if it exists and is valid
	if _hover_tween and _hover_tween.is_valid():
		_hover_tween.kill()
		
	_hover_tween = get_tree().create_tween() # Store the tween reference
	_hover_tween.bind_node(self) # Binding to self for cleanup
	
	_hover_tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	_hover_tween.tween_property(self, "scale", original_scale, HOVER_ANIM_DURATION)

func play_equip_impact_vfx() -> void:
	print("DEBUG (EquipSlot:", name, "): play_equip_impact_vfx() called!")
	print("DEBUG (EquipSlot:", name, "): ItemIcon position at start of VFX: ", item_icon.position)
	print("DEBUG (EquipSlot:", name, "): EquipSlot position at start of VFX: ", position)
	print("DEBUG (EquipSlot:", name, "): EquipSlot global_position at start of VFX: ", global_position)

	# Kill previous icon impact tween if it exists and is valid
	if _icon_tween and _icon_tween.is_valid():
		_icon_tween.kill()
	item_icon.scale = Vector2(1,1) # Reset for the new pop animation

	_icon_tween = get_tree().create_tween()
	_icon_tween.bind_node(item_icon)
	
	_icon_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	_icon_tween.tween_property(item_icon, "scale", Vector2(1.2, 1.2), 0.08)
	_icon_tween.tween_property(item_icon, "scale", Vector2(1.0, 1.0), 0.15)
	
	# Kill previous shake tween if it exists and is valid
	if _shake_tween and _shake_tween.is_valid():
		_shake_tween.kill()
	
	# This line uses the 'original_position' that is now correctly updated in setup_slot()
	position = original_position 
	print("DEBUG (EquipSlot:", name, "): EquipSlot position RESET to original_position: ", position)


	_shake_tween = get_tree().create_tween()
	_shake_tween.bind_node(self) # Binding to self for cleanup
	
	_shake_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	_shake_tween.tween_property(self, "position", original_position + Vector2(5, 0), 0.05) # Shake right
	_shake_tween.tween_property(self, "position", original_position + Vector2(-5, 0), 0.05) # Shake left
	_shake_tween.tween_property(self, "position", original_position + Vector2(5, 0), 0.05) # Shake right again
	_shake_tween.tween_property(self, "position", original_position, 0.05) # Return to original
	print("DEBUG (EquipSlot:", name, "): Shake tweens set for EquipSlot position. Target (final) position: ", original_position)

	if equip_particles:
		print("DEBUG (EquipSlot:", name, "): equip_particles node reference is NOT null.")
		# --- MODIFIED LINE HERE ---
		# Added Vector2(35, 40) to move particles 35px right and 40px down from the icon's center.
		equip_particles.position = item_icon.position + item_icon.size / 2.0
		 #+ Vector2(35, 40)
		equip_particles.emitting = true
		if equip_particles.one_shot:
			equip_particles.restart()
			print("DEBUG (EquipSlot:", name, "): equip_particles.restart() called (one_shot enabled).")
		else:
			print("DEBUG (EquipSlot:", name, "): equip_particles.emitting = true set (one_shot disabled).")
	else:
		print("DEBUG (EquipSlot:", name, "): ERROR! equip_particles node reference is NULL.")

	if equip_sound_player and equip_sound_player.stream:
		equip_sound_player.play()
	else:
		print("EquipSlot WARNING: No sound assigned to EquipSoundPlayer or stream is null.")
