extends Control

const CHEST_COOLDOWN := 0.2 # seconds (for individual button cooldown)
const MIN_ITEM_DISPLAY_DURATION := 0.4 # seconds (how long item must be visible)
const POST_CLEANUP_COOLDOWN_TIME := 0.3 # seconds (dead zone after chest closes)

enum ChestState {
	IDLE,
	OPENING_CHEST_ANIMATION,
	ITEM_DROPPING,
	ITEM_DISPLAYED_WAITING_FOR_TAP,
	COLLECTING_ITEM_ANIMATION,
	POST_CLEANUP_COOLDOWN
}

var current_chest_state: ChestState = ChestState.IDLE # Initialize to IDLE
var _item_drop_start_time: float = 0.0 # To store the time when the item drop animation started


var waiting_for_tap := false
var tapped_early := false

var _current_dropped_item_sprite: Sprite2D = null
var _current_dropped_item_path: String = ""
var _current_dropped_item_rarity: String = ""
var _item_drop_tween: Tween = null


func _ready() -> void:
	%coin_count.text = str(Autoload.player_coins)
	%TextureRect.hide()
	%"chest-normal2".hide()
	%"chest-bloody2".hide()
	%"chest-gold2".hide()
	%"chest-legendary2".hide()
	
	# Initialize state and enable buttons
	current_chest_state = ChestState.IDLE
	_set_chest_buttons_enabled(true)
	print("DEBUG: Game initialized. State: IDLE")


func _open_chest(cost: int, button: Button, chest: AnimatedSprite2D) -> void:
	# This function is called from _on_button_X_pressed where waiting_for_tap is set
	# and current_chest_state should be OPENING_CHEST_ANIMATION.
	
	_item_drop_start_time = 0.0 # Reset for the new chest opening process
	print("DEBUG: _item_drop_start_time reset to 0.0 for new chest.")

	if Autoload.player_coins >= cost:
		Autoload.player_coins -= cost
		Autoload.save_coins()
		%coin_count.text = str(Autoload.player_coins)

		# Disable the specific button pressed immediately for its own cooldown
		button.disabled = true
		await get_tree().create_timer(CHEST_COOLDOWN).timeout
		button.disabled = false # Re-enable this specific button after its cooldown

		# Show chest open animation elements
		chest.show()
		%TextureRect.show()
		%AnimationPlayer.play("glow_pulse")
		
		# Immediately disable all chest buttons as chest opening begins
		_set_chest_buttons_enabled(false)
		print("DEBUG: All chest buttons disabled during chest opening. State: OPENING_CHEST_ANIMATION")

		# Start the chest opening animation
		chest.play("default") # Assumes "default" is the opening animation

		# Await the chest animation to finish before dropping item
		print("DEBUG: Waiting for chest animation to finish...")
		await chest.animation_finished
		print("DEBUG: Chest animation finished. State transition to ITEM_DROPPING.")
		current_chest_state = ChestState.ITEM_DROPPING


		# Drop the item and start its animation
		var chest_name = chest.name.to_lower()
		if "normal" in chest_name:
			drop_random_image("normal")
		elif "bloody" in chest_name:
			drop_random_image("bloody")
		elif "gold" in chest_name:
			drop_random_image("gold")
		elif "legendary" in chest_name:
			drop_random_image("legendary")

		print("Chest opened for ", cost)
	else:
		%text_anim.play("not_enough_coins")
		# If not enough coins, immediately go back to IDLE state and re-enable buttons
		current_chest_state = ChestState.IDLE
		_set_chest_buttons_enabled(true)
		
		# Also reset waiting_for_tap if not enough coins, so other buttons can be pressed
		waiting_for_tap = false 
		
		print("DEBUG: Not enough coins. State: IDLE.")
	
	# Removed %Label6.show() from here. It will be managed by _animate_item_drop
	# when the item is fully displayed.


# Individual button press functions - keeping as requested
func _on_button_1_pressed() -> void:
	if current_chest_state != ChestState.IDLE: # Use state as primary guard
		print("DEBUG: Button 1 pressed, but not in IDLE state. Current state:", current_chest_state)
		return
	
	# Set flags for old logic (waiting_for_tap, tapped_early)
	waiting_for_tap = true
	tapped_early = false
	
	current_chest_state = ChestState.OPENING_CHEST_ANIMATION # Set state as opening begins
	print("DEBUG: Button 1 pressed. State: OPENING_CHEST_ANIMATION")
	
	_open_chest(40, %Button1, %"chest-normal2")
	
	# This timer is for the "tap_continue" text. The actual state transition
	# to ITEM_DISPLAYED_WAITING_FOR_TAP is managed in _animate_item_drop.
	await get_tree().create_timer(2).timeout
	if not tapped_early and current_chest_state == ChestState.ITEM_DISPLAYED_WAITING_FOR_TAP:
		# Only show "tap_continue" if we are still waiting for a tap and it wasn't already tapped
		%text_anim.play("tap_continue")


func _on_button_2_pressed() -> void:
	if current_chest_state != ChestState.IDLE: return
	waiting_for_tap = true
	tapped_early = false
	current_chest_state = ChestState.OPENING_CHEST_ANIMATION
	_open_chest(200, %Button2, %"chest-bloody2")
	await get_tree().create_timer(2).timeout
	if not tapped_early and current_chest_state == ChestState.ITEM_DISPLAYED_WAITING_FOR_TAP:
		%text_anim.play("tap_continue")

func _on_button_3_pressed() -> void:
	if current_chest_state != ChestState.IDLE: return
	waiting_for_tap = true
	tapped_early = false
	current_chest_state = ChestState.OPENING_CHEST_ANIMATION
	_open_chest(800, %Button3, %"chest-gold2")
	await get_tree().create_timer(2).timeout
	if not tapped_early and current_chest_state == ChestState.ITEM_DISPLAYED_WAITING_FOR_TAP:
		%text_anim.play("tap_continue")

func _on_button_4_pressed() -> void:
	if current_chest_state != ChestState.IDLE: return
	waiting_for_tap = true
	tapped_early = false
	current_chest_state = ChestState.OPENING_CHEST_ANIMATION
	_open_chest(4000, %Button4, %"chest-legendary2")
	await get_tree().create_timer(2).timeout
	if not tapped_early and current_chest_state == ChestState.ITEM_DISPLAYED_WAITING_FOR_TAP:
		%text_anim.play("tap_continue")



func _unhandled_input(event: InputEvent) -> void:
	# Primary guard: only handle taps if waiting_for_tap is true (from button press)
	if not waiting_for_tap: 
		print("DEBUG: _unhandled_input: Tap ignored. waiting_for_tap is false.")
		return
	
	# Secondary guard: only process taps for collection if in the correct state
	if current_chest_state != ChestState.ITEM_DISPLAYED_WAITING_FOR_TAP:
		print("DEBUG: _unhandled_input: Tap ignored. Not in ITEM_DISPLAYED_WAITING_FOR_TAP state. Current state:", current_chest_state)
		return
	
	var is_tap = ((event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed))
	
	if is_tap:
		# Check if the minimum display time has passed
		var elapsed_since_drop = Time.get_unix_time_from_system() - _item_drop_start_time
		
		# Only check the minimum duration if _item_drop_start_time has been set (i.e., item is visible)
		if _item_drop_start_time != 0.0 and elapsed_since_drop < MIN_ITEM_DISPLAY_DURATION:
			print("DEBUG: Tap ignored. Item must be displayed for at least ", MIN_ITEM_DISPLAY_DURATION, " seconds. Elapsed: ", elapsed_since_drop)
			return # Exit the function, ignoring the tap
		
		print("DEBUG: Minimum display duration met. State transition to COLLECTING_ITEM_ANIMATION.")
		current_chest_state = ChestState.COLLECTING_ITEM_ANIMATION

		# Set tapped_early to true immediately so the 2-second timer doesn't show "tap_continue"
		tapped_early = true 
		
		# If there's a dropped item, add it to inventory before cleaning up
		if _current_dropped_item_sprite and is_instance_valid(_current_dropped_item_sprite):
			_add_item_to_inventory() # Call the dedicated function for inventory logic
		
		# Now, perform all visual cleanup and reset state
		_cleanup_chest_display()




# NEW FUNCTION: Handles adding the item to inventory
func _add_item_to_inventory() -> void:
	if Autoload.has_node("Inventory"):
		Autoload.Inventory.add_item(_current_dropped_item_path, _current_dropped_item_rarity)
		print("Item added to inventory: ", _current_dropped_item_path)
	else:
		print("WARNING: Autoload 'Inventory' not found. Item was not added to inventory.")



# NEW FUNCTION: Centralized cleanup for chest display and dropped item
func _cleanup_chest_display() -> void:
	print("DEBUG: --- Starting _cleanup_chest_display ---. Current State:", current_chest_state)

	# IMPORTANT FIX: Reset these flags *immediately* to prevent re-entry
	# if the user taps multiple times quickly or tries to re-open a chest.
	waiting_for_tap = false
	tapped_early = false # Also reset tapped_early to clean state for next chest

	# 1. Hide all chest visuals and stop text animation
	for chest in [%"chest-normal2",%"chest-bloody2",%"chest-gold2",%"chest-legendary2"]:
		chest.hide()
	%TextureRect.hide()
	%text_anim.stop()
	%Label6.hide() # Hide "Tap to continue" label

	# NEW: Reset _item_drop_start_time when the chest is cleaned up
	_item_drop_start_time = 0.0
	print("DEBUG: _item_drop_start_time reset to 0.0.")


	# 2. Handle the dropped item sprite if it still exists and is valid
	if _current_dropped_item_sprite and is_instance_valid(_current_dropped_item_sprite):
		print("DEBUG: _cleanup_chest_display: Item sprite exists and is valid. Handling its removal.")
		
		# Kill any active tweens on it (drop animation or hover)
		if _item_drop_tween and _item_drop_tween.is_valid() and _item_drop_tween.is_running():
			print("DEBUG: _cleanup_chest_display: Killing active item drop tween.")
			_item_drop_tween.kill()
		
		# Animate the item's disappearance (collection effect)
		var collection_tween = create_tween()
		collection_tween.set_parallel(true)
		collection_tween.tween_property(_current_dropped_item_sprite, "scale", Vector2(0.1, 0.1), 0.2).set_ease(Tween.EASE_IN)
		collection_tween.tween_property(_current_dropped_item_sprite, "modulate", Color(1, 1, 1, 0), 0.2).set_ease(Tween.EASE_IN)
		
		print("DEBUG: _cleanup_chest_display: Awaiting collection animation to finish.")
		await collection_tween.finished
		print("DEBUG: _cleanup_chest_display: Collection animation finished.")

		# Free the sprite AFTER its disappearance animation
		_current_dropped_item_sprite.queue_free()
		print("DEBUG: _cleanup_chest_display: Item sprite queued for free.")
	else:
		print("DEBUG: _cleanup_chest_display: No item sprite to handle or invalid instance.")

	# 3. Clear all references
	_current_dropped_item_sprite = null
	_item_drop_tween = null
	_current_dropped_item_path = ""
	_current_dropped_item_rarity = ""
	
	# Transition to POST_CLEANUP_COOLDOWN state
	current_chest_state = ChestState.POST_CLEANUP_COOLDOWN
	print("DEBUG: State: POST_CLEANUP_COOLDOWN. Waiting for cooldown.")

	# Add a small cooldown *after* all visuals are hidden and before re-enabling buttons
	await get_tree().create_timer(POST_CLEANUP_COOLDOWN_TIME).timeout
	print("DEBUG: Post-cleanup cooldown finished.")

	# Re-enable all chest buttons and return to IDLE state
	_set_chest_buttons_enabled(true)
	current_chest_state = ChestState.IDLE
	print("DEBUG: All chest buttons re-enabled. State: IDLE.")
	
	print("DEBUG: --- Exiting _cleanup_chest_display ---")



# The old _collect_item and _hide_all_chests functions are now replaced/removed
# Their logic is integrated into _add_item_to_inventory and _cleanup_chest_display


# NEW HELPER FUNCTION: To enable or disable all chest buttons
func _set_chest_buttons_enabled(enabled: bool) -> void:
	%Button1.disabled = not enabled
	%Button2.disabled = not enabled
	%Button3.disabled = not enabled
	%Button4.disabled = not enabled



func _on_button_1_mouse_entered() -> void:
	var label = %Label
	label.add_theme_font_size_override("font_size", 32)
	%Coin2.set_scale(Vector2(2.6, 2.6))
func _on_button_1_mouse_exited() -> void:
	var label = %Label
	label.add_theme_font_size_override("font_size", 24)
	%Coin2.set_scale(Vector2(2, 2))

func _on_button_2_mouse_entered() -> void:
	var label = %Label2
	label.add_theme_font_size_override("font_size", 32)
	%Coin3.set_scale(Vector2(2.6, 2.6))
func _on_button_2_mouse_exited() -> void:
	var label = %Label2
	label.add_theme_font_size_override("font_size", 24)
	%Coin3.set_scale(Vector2(2, 2))

func _on_button_3_mouse_entered() -> void:
	var label = %Label3
	label.add_theme_font_size_override("font_size", 32)
	%Coin4.set_scale(Vector2(2.6, 2.6))
func _on_button_3_mouse_exited() -> void:
	var label = %Label3
	label.add_theme_font_size_override("font_size", 24)
	%Coin4.set_scale(Vector2(2, 2))

func _on_button_4_mouse_entered() -> void:
	var label = %Label4
	label.add_theme_font_size_override("font_size", 32)
	%Coin5.set_scale(Vector2(2.6, 2.6))
func _on_button_4_mouse_exited() -> void:
	var label = %Label4
	label.add_theme_font_size_override("font_size", 24)
	%Coin5.set_scale(Vector2(2, 2))


## --- RARITY DROP SYSTEM ---
func get_rarity_from_filename(filename: String) -> String:
	filename = filename.to_lower()
	if "_legendary" in filename: return "legendary"
	elif "_epic" in filename: return "epic"
	elif "_rare" in filename: return "rare"
	elif "_common" in filename: return "common"
	return "common"

func is_valid_rarity_for_chest(chest_type: String, rarity: String) -> bool:
	match chest_type:
		"normal": return rarity == "common"
		"bloody": return rarity in ["common", "rare"]
		"gold": return rarity in ["rare", "epic"]
		"legendary": return rarity in ["common", "rare", "epic", "legendary"]
	return false

func drop_random_image(chest_type: String):
	print("DEBUG: --- Starting drop_random_image for chest_type:", chest_type, " ---")
	var valid_paths = []
	var root = "res://assets/drop-assets"
	var stack = [root]
	print("DEBUG: Starting directory scan from:", root)

	while not stack.is_empty():
		var current_path = stack.pop_back()
		var dir = DirAccess.open(current_path)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if dir.current_is_dir() and not file_name.begins_with("."):
					stack.append(current_path + "/" + file_name)
				elif file_name.ends_with(".png"):
					var rarity = get_rarity_from_filename(file_name)
					if is_valid_rarity_for_chest(chest_type, rarity):
						valid_paths.append(current_path + "/" + file_name)
						print("DEBUG: Valid item found and added:", current_path + "/" + file_name, " (Rarity:", rarity, ")")
				file_name = dir.get_next()
			dir.list_dir_end()
		else:
			print("ERROR: Could not open directory:", current_path, ". Check path and permissions.")

	print("DEBUG: Finished directory scan. Total valid paths found:", valid_paths.size())

	if valid_paths.size() > 0:
		var image_path = valid_paths[randi() % valid_paths.size()]
		print("DEBUG: Selected image path for drop:", image_path)
		var texture = load(image_path)
		if texture and texture is Texture2D:
			print("DEBUG: Texture loaded successfully for:", image_path)
			
			# Clean up any previous item and its tween before creating a new one
			if _current_dropped_item_sprite and is_instance_valid(_current_dropped_item_sprite):
				_current_dropped_item_sprite.queue_free()
				_current_dropped_item_sprite = null
			if _item_drop_tween and _item_drop_tween.is_valid() and _item_drop_tween.is_running():
				_item_drop_tween.kill()
				_item_drop_tween = null

			var sprite = Sprite2D.new()
			sprite.texture = texture
			sprite.position = Vector2(960, 500)
			sprite.set_z_index(5)
			add_child(sprite)
			print("DEBUG: Sprite created and added to scene tree. Node name:", sprite.name, " ID:", sprite.get_instance_id())
			print("DEBUG: Initial sprite properties BEFORE _animate_item_drop call: Position:", sprite.position, " Scale:", sprite.scale, " Modulate:", sprite.modulate)

			_current_dropped_item_sprite = sprite
			_current_dropped_item_path = image_path
			_current_dropped_item_rarity = get_rarity_from_filename(image_path)

			_animate_item_drop(sprite)
		else:
			print("ERROR: Failed to load texture from path:", image_path)
	else:
		print("INFO: No valid drops for chest:", chest_type, ". Check file paths and rarity names.")


func _animate_item_drop(sprite: Sprite2D) -> void:
	print("DEBUG: --- Starting _animate_item_drop for sprite ID:", sprite.get_instance_id(), " ---")

	if _item_drop_tween and _item_drop_tween.is_valid() and _item_drop_tween.is_running():
		print("DEBUG: Killing existing _item_drop_tween.")
		_item_drop_tween.kill()
	_item_drop_tween = null

	var final_y_position = sprite.position.y
	var initial_y_position = final_y_position - 150 # Start higher for drop effect

	sprite.position = Vector2(sprite.position.x, initial_y_position)
	sprite.scale = Vector2(0.1, 0.1)
	sprite.modulate = Color(1, 1, 1, 0) # Start invisible
	print("DEBUG: _animate_item_drop: Sprite initial properties set: Position:", sprite.position, " Scale:", sprite.scale, " Modulate:", sprite.modulate)


	_item_drop_tween = create_tween()
	_item_drop_tween.set_parallel(true)


	# Initial drop animation
	_item_drop_tween.tween_property(sprite, "position:y", final_y_position, 0.6) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
	_item_drop_tween.tween_property(sprite, "scale", Vector2(6, 6), 0.4) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_item_drop_tween.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.3) \
		.set_ease(Tween.EASE_OUT)
	
	print("DEBUG: _animate_item_drop: Initial parallel tweens added.")

	# Await the completion of the initial drop animation
	await _item_drop_tween.finished
	print("DEBUG: _animate_item_drop: Initial drop animation finished.")

	# Now chain the subtle hover animation (which will loop indefinitely)
	var hover_subtween = create_tween()
	hover_subtween.tween_property(sprite, "position:y", final_y_position - 10, 0.8) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	hover_subtween.tween_property(sprite, "position:y", final_y_position, 0.8) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	hover_subtween.set_loops()
	# No need to chain to _item_drop_tween directly here, as it's already finished.
	# Just start the hover_subtween.
	hover_subtween.play() 
	print("DEBUG: _animate_item_drop: Hover subtween started.")

	# Record the time the item is fully displayed and visible for collection
	_item_drop_start_time = Time.get_unix_time_from_system()
	
	# Transition state to ITEM_DISPLAYED_WAITING_FOR_TAP and show prompt
	current_chest_state = ChestState.ITEM_DISPLAYED_WAITING_FOR_TAP
	%Label6.show() # Show "Tap to continue" label
	# The text_anim.play("tap_continue") might also be called from _on_button_X_pressed
	# if tapped_early is false. We ensure it's displayed here if needed.
	if not %text_anim.is_playing(): # Avoid re-playing if already active from _on_button_X_pressed
		%text_anim.play("tap_continue") 
	print("DEBUG: _animate_item_drop: Item fully displayed. State: ITEM_DISPLAYED_WAITING_FOR_TAP. Prompting user.")

	print("DEBUG: --- Exiting _animate_item_drop ---")
