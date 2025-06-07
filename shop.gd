extends Control # Assuming this is your base class

const CHEST_COOLDOWN := 0.2 # seconds (for individual button cooldown)
const MIN_ITEM_DISPLAY_DURATION := 0.4 # seconds (how long item must be visible)
const POST_CLEANUP_COOLDOWN_TIME := 0.3 # seconds (dead zone after chest closes)


#---------ADS-----------
@onready var ad_button: Button = %AdButton
@onready var admob: Admob = %Admob

var is_initialized : bool = false
#-------------------------

@onready var player_level_label: Label = %PlayerLevelLabel
@onready var item_count_label: Label = %ItemCountLabel

const INITIAL_AD_REWARD :int= 100 # Coins awarded at player level 0
const AD_REWARD_PER_LEVEL_MULTIPLIER :int= 50 # Additional coins per player levelt
var earned_coins: int = 0


const CHEST_DROP_CHANCES = {
	"normal": {
		"common": 1.0,    # 100% common
		"rare": 0.0,
		"epic": 0.0,
		"legendary": 0.0
	},
	"bloody": {
		"common": 0.7,    # 70% common, 30% rare
		"rare": 0.3,
		"epic": 0.0,
		"legendary": 0.0
	},
	"gold": {
		"common": 0.0,
		"rare": 0.6,    # 60% rare, 40% epic
		"epic": 0.4,
		"legendary": 0.0
	},
	"legendary": {
		"common": 0.05,  # 5% common
		"rare": 0.15,    # 15% rare
		"epic": 0.3,      # 30% epic
		"legendary": 0.5 # 50% legendary
	}
}

enum ChestState {
	IDLE,
	OPENING_CHEST_ANIMATION,
	ITEM_DROPPING,
	ITEM_DISPLAYED_WAITING_FOR_TAP,
	COLLECTING_ITEM_ANIMATION,
	POST_CLEANUP_COOLDOWN
}

var current_chest_state: ChestState = ChestState.IDLE
var _item_drop_start_time: float = 0.0

var waiting_for_tap := false
var tapped_early := false

var _current_dropped_item_sprite: Sprite2D = null
var _current_dropped_item_path: String = ""
var _current_dropped_item_rarity: String = ""
var _item_drop_tween: Tween = null
var _current_dropped_item_id_for_inventory: String = ""

var items_by_rarity_dict: Dictionary = {}

func _ready() -> void:
	await get_tree().create_timer(0.01).timeout
	%coin_count.text = _format_coin_amount(Autoload.player_coins)
	
	%TextureRect.hide()
	%"chest-normal2".hide()
	%"chest-bloody2".hide()
	%"chest-gold2".hide()
	%"chest-legendary2".hide()
	
	%RarityLabel.hide()
	%ItemNameLabel.hide()
	
	_populate_items_by_rarity()

	current_chest_state = ChestState.IDLE
	_set_chest_buttons_enabled(true)
	print("DEBUG: Game initialized. State: IDLE")
	
	# Removed _update_ad_labels() as it's ad-related
	
	_update_player_progress_labels()
	
	admob.initialize()
	
	# Removed entire AdMob initialization block
	# if admob_node:
	#     print("DEBUG: Admob node found. Initializing and connecting signals.")
	#     admob_node.initialize()
	#     admob_node.initialization_completed.connect(_on_admob_initialization_completed)
	#     admob_node.rewarded_ad_loaded.connect(_on_rewarded_ad_loaded)
	#     admob_node.rewarded_ad_failed_to_load.connect(_on_rewarded_ad_failed_to_load)
	#     admob_node.rewarded_ad_dismissed_full_screen_content.connect(_on_rewarded_ad_dismissed_full_screen_content)
	#     admob_node.rewarded_ad_user_earned_reward.connect(_on_rewarded_ad_user_earned_reward)
	# else:
	#     print("ERROR: Admob node not found in scene. Ad functions will not work.")
	#     _set_ad_button_enabled(false)


func _calculate_ad_reward() -> int:
	var current_level = max(0, Autoload.player_level)
	earned_coins = INITIAL_AD_REWARD + (current_level * AD_REWARD_PER_LEVEL_MULTIPLIER)
	return earned_coins

func _format_coin_amount(amount: int) -> String:
	if amount >= 1000000:
		return "%.1fM" % (float(amount) / 1000000.0)
	elif amount >= 1000:
		return "%.1fk" % (float(amount) / 1000.0)
	else:
		return str(amount)

func _update_player_progress_labels() -> void:
	if player_level_label:
		player_level_label.text = "Level: " + str(Autoload.player_level)
	
	if item_count_label:
		var total_items = 0
		for item_id in Autoload.player_inventory:
			total_items += Autoload.player_inventory[item_id]
		item_count_label.text = "Items: " + str(total_items)
	
	# Removed _update_ad_labels()
	
## --- AD-RELATED FUNCTIONS ---
# Removed func _on_admob_initialization_completed(...)
# Removed func _on_ad_button_pressed()
# Removed func _on_rewarded_ad_loaded(...)
# Removed func _on_rewarded_ad_failed_to_load(...)
# Removed func _on_rewarded_ad_dismissed_full_screen_content(...)
# Removed func _on_rewarded_ad_user_earned_reward(...)
# Removed func _update_ad_labels()

## --- Dynamically Populates items_by_rarity_dict ---
func _populate_items_by_rarity() -> void:
	print("DEBUG: Populating items_by_rarity_dict dynamically...")
	items_by_rarity_dict.clear()

	var base_dir = "res://assets/drop-assets/"
	var dir = DirAccess.open(base_dir)

	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				var sub_dir_path = base_dir + file_name + "/"
				_scan_directory_for_items(sub_dir_path)
			elif file_name.ends_with(".png") or file_name.ends_with(".jpg"):
				var full_path = base_dir + file_name
				_add_item_path_to_rarity_dict(full_path)
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		print("ERROR: Could not open directory for item scanning: ", base_dir)

	print("DEBUG: Finished populating items_by_rarity_dict:", items_by_rarity_dict)

func _scan_directory_for_items(path: String) -> void:
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				_scan_directory_for_items(path + file_name + "/")
			elif file_name.ends_with(".png") or file_name.ends_with(".jpg"):
				var full_path = path + file_name
				_add_item_path_to_rarity_dict(full_path)
			file_name = dir.get_next()
		dir.list_dir_end()

func _add_item_path_to_rarity_dict(path: String) -> void:
	var rarity = get_rarity_from_filename(path.get_file())
	if not items_by_rarity_dict.has(rarity):
		items_by_rarity_dict[rarity] = []
	items_by_rarity_dict[rarity].append(path)
	print("DEBUG SHOP: Scanned item: ", path, " (Rarity: ", rarity, ")")

	var item_id_from_filename = path.get_file().get_basename()
	if get_node_or_null("/root/ItemData"):
		ItemData.register_item_path(item_id_from_filename, path)
		print("DEBUG SHOP: Registered item_id '", item_id_from_filename, "' with path: '", path, "' in ItemData.")
	else:
		print("Shop WARNING: ItemData Autoload not found. Cannot register item path for:", item_id_from_filename)

## --- CHEST OPENING LOGIC ---
func _open_chest(cost: int, button: Button, chest: AnimatedSprite2D) -> void:
	_item_drop_start_time = 0.0
	print("DEBUG: _item_drop_start_time reset to 0.0 for new chest.")

	if Autoload.player_coins >= cost:
		Autoload.player_coins -= cost
		Autoload.save_all_player_data()
		%coin_count.text = _format_coin_amount(Autoload.player_coins)

		button.disabled = true
		await get_tree().create_timer(CHEST_COOLDOWN).timeout
		button.disabled = false

		chest.show()
		%TextureRect.show()
		%AnimationPlayer.play("glow_pulse")
		
		_set_chest_buttons_enabled(false)
		# Removed _set_ad_button_enabled(false)
		print("DEBUG: All chest buttons disabled during chest opening. State: OPENING_CHEST_ANIMATION")

		chest.play("default")

		print("DEBUG: Waiting for chest animation to finish...")
		await chest.animation_finished
		print("DEBUG: Chest animation finished. State transition to ITEM_DROPPING.")
		current_chest_state = ChestState.ITEM_DROPPING

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
		current_chest_state = ChestState.IDLE
		_set_chest_buttons_enabled(true)
		# Removed _set_ad_button_enabled(true)
		
		waiting_for_tap = false    
		
		print("DEBUG: Not enough coins. State: IDLE.")

## --- CHEST BUTTON PRESSED FUNCTIONS ---
func _on_button_1_pressed() -> void:
	if current_chest_state != ChestState.IDLE: return
	waiting_for_tap = true
	tapped_early = false
	current_chest_state = ChestState.OPENING_CHEST_ANIMATION
	print("DEBUG: Button 1 pressed. State: OPENING_CHEST_ANIMATION")
	
	_open_chest(40, %Button1, %"chest-normal2")
	
	await get_tree().create_timer(2).timeout
	if not tapped_early and current_chest_state == ChestState.ITEM_DISPLAYED_WAITING_FOR_TAP:
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

## --- INPUT AND ITEM COLLECTION ---
func _unhandled_input(event: InputEvent) -> void:
	if not waiting_for_tap:    
		return
	
	if current_chest_state != ChestState.ITEM_DISPLAYED_WAITING_FOR_TAP:
		return
	
	var is_tap = ((event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed))
	
	if is_tap:
		var elapsed_since_drop = Time.get_unix_time_from_system() - _item_drop_start_time
		
		if _item_drop_start_time != 0.0 and elapsed_since_drop < MIN_ITEM_DISPLAY_DURATION:
			return
		
		current_chest_state = ChestState.COLLECTING_ITEM_ANIMATION

		tapped_early = true    
		
		if _current_dropped_item_sprite and is_instance_valid(_current_dropped_item_sprite):
			_add_item_to_inventory()
		
		_cleanup_chest_display()

func _add_item_to_inventory() -> void:
	if get_node_or_null("/root/Autoload"):
		Autoload.add_item_to_inventory(_current_dropped_item_id_for_inventory, 1)
		print("CHEST: Item ", _current_dropped_item_id_for_inventory, " added to inventory.")
		_update_player_progress_labels()
	else:
		print("CHEST WARNING: Autoload 'Autoload' not found. Item was not added to inventory.")
	
	_current_dropped_item_id_for_inventory = ""

## --- CLEANUP (MODIFIED TO RE-ENABLE ALL BUTTONS) ---
func _cleanup_chest_display() -> void:
	print("DEBUG: --- Starting _cleanup_chest_display ---. Current State:", current_chest_state)

	waiting_for_tap = false
	tapped_early = false

	for chest in [%"chest-normal2",%"chest-bloody2",%"chest-gold2",%"chest-legendary2"]:
		chest.hide()
	%TextureRect.hide()
	%text_anim.stop()
	%Label6.hide()
	%RarityLabel.hide() # Ensure rarity label is hidden
	%ItemNameLabel.hide() # Ensure item name label is hidden

	_item_drop_start_time = 0.0
	print("DEBUG: _item_drop_start_time reset to 0.0.")

	if _current_dropped_item_sprite and is_instance_valid(_current_dropped_item_sprite):
		print("DEBUG: _cleanup_chest_display: Item sprite exists and is valid. Handling its removal.")
		
		if _item_drop_tween and _item_drop_tween.is_valid() and _item_drop_tween.is_running():
			print("DEBUG: _cleanup_chest_display: Killing active item drop tween.")
			_item_drop_tween.kill()
		
		var collection_tween = create_tween()
		collection_tween.set_parallel(true)
		collection_tween.tween_property(_current_dropped_item_sprite, "scale", Vector2(0.1, 0.1), 0.2).set_ease(Tween.EASE_IN)
		collection_tween.tween_property(_current_dropped_item_sprite, "modulate", Color(1, 1, 1, 0), 0.2).set_ease(Tween.EASE_IN)
		
		print("DEBUG: _cleanup_chest_display: Awaiting collection animation to finish.")
		await collection_tween.finished
		print("DEBUG: _cleanup_chest_display: Collection animation finished.")

		_current_dropped_item_sprite.queue_free()
		print("DEBUG: _cleanup_chest_display: Item sprite queued for free.")
	else:
		print("DEBUG: _cleanup_chest_display: No item sprite to handle or invalid instance.")

	_current_dropped_item_sprite = null
	_item_drop_tween = null
	_current_dropped_item_path = ""
	_current_dropped_item_rarity = ""
	_current_dropped_item_id_for_inventory = ""

	current_chest_state = ChestState.POST_CLEANUP_COOLDOWN
	print("DEBUG: State: POST_CLEANUP_COOLDOWN. Waiting for cooldown.")

	await get_tree().create_timer(POST_CLEANUP_COOLDOWN_TIME).timeout
	print("DEBUG: Post-cleanup cooldown finished.")

	_set_chest_buttons_enabled(true)
	# Removed _set_ad_button_enabled(true)
	current_chest_state = ChestState.IDLE
	print("DEBUG: All chest buttons re-enabled. State: IDLE.")
	
	print("DEBUG: --- Exiting _cleanup_chest_display ---")

## --- BUTTON ENABLE/DISABLE ---
func _set_chest_buttons_enabled(enabled: bool) -> void:
	%Button1.disabled = not enabled
	%Button2.disabled = not enabled
	%Button3.disabled = not enabled
	%Button4.disabled = not enabled

# Removed func _set_ad_button_enabled(enabled: bool)

## --- MOUSE HOVER ANIMATIONS ---
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

# MODIFIED: This function now creates the Sprite2D and passes it to _animate_item_drop
func drop_random_image(chest_type: String) -> void:
	print("DEBUG: drop_random_image called for chest_type:", chest_type)

	if not CHEST_DROP_CHANCES.has(chest_type):
		print("ERROR: Unknown chest type: ", chest_type, ". Defaulting to normal chest drops.")
		chest_type = "normal"

	var chosen_rarity = _get_random_rarity(chest_type) # Changed to use _get_random_rarity
	print("DEBUG: Chosen rarity for ", chest_type, " chest: ", chosen_rarity)

	if items_by_rarity_dict.has(chosen_rarity) and not items_by_rarity_dict[chosen_rarity].is_empty():
		var available_items: Array = items_by_rarity_dict[chosen_rarity]
		var random_index = randi() % available_items.size()
		_current_dropped_item_path = available_items[random_index]
		
		# This line correctly derives the Item.id from the image path's base filename.
		_current_dropped_item_id_for_inventory = _current_dropped_item_path.get_file().get_basename()

		print("DEBUG: Dropped item path: ", _current_dropped_item_path, " (ID: ", _current_dropped_item_id_for_inventory, ")")

		var texture: Texture2D = load(_current_dropped_item_path)
		if texture:
			var sprite = Sprite2D.new()
			sprite.texture = texture
			
			# Set initial position and Z-index
			sprite.position = Vector2(950, 400) # This is where the item will animate *to* initially
			sprite.z_index = 10 # Crucial: ensures the item draws on top of other UI elements
			add_child(sprite)

			_current_dropped_item_sprite = sprite # Store reference to the sprite
			_current_dropped_item_rarity = chosen_rarity # Store rarity

			# Setup RarityLabel and ItemNameLabel *before* animation starts
			var rarity_color = get_color_for_rarity(_current_dropped_item_rarity)
			%RarityLabel.text = _current_dropped_item_rarity.capitalize()
			%RarityLabel.add_theme_color_override("font_color", rarity_color)
			%RarityLabel.show()

			var item_name = ""
			if get_node_or_null("/root/ItemData"):
				var dropped_item_resource = ItemData.get_item_by_id(_current_dropped_item_id_for_inventory)
				if dropped_item_resource:
					item_name = dropped_item_resource.item_name
					print("DEBUG SHOP: Retrieved item name from ItemData: ", item_name)
				else:
					item_name = _current_dropped_item_id_for_inventory.capitalize().replace("_", " ")
					print("DEBUG SHOP: ItemData exists but returned null for item ID. Derived name: ", item_name)
			else:
				item_name = _current_dropped_item_id_for_inventory.capitalize().replace("_", " ")
				print("DEBUG SHOP: ItemData Autoload not found. Derived name: ", item_name)
			
			%ItemNameLabel.text = item_name
			%ItemNameLabel.add_theme_color_override("font_color", rarity_color)
			%ItemNameLabel.show()

			_animate_item_drop(sprite) # Pass the created sprite to the animation function
		else:
			print("ERROR: Could not load texture for path: ", _current_dropped_item_path)
			_cleanup_chest_display() # Clean up if texture fails to load
	else:
		print("ERROR: No items found for rarity: ", chosen_rarity, " or dictionary is empty for this rarity.")
		_current_dropped_item_path = ""
		_current_dropped_item_rarity = ""
		_current_dropped_item_id_for_inventory = ""
		_cleanup_chest_display()

# Renamed to match the private function naming convention
func _get_random_rarity(chest_type: String) -> String:
	var chances_for_chest = CHEST_DROP_CHANCES[chest_type]
	var rand_value = randf()

	var cumulative_chance = 0.0
	for rarity in ["legendary", "epic", "rare", "common"]:
		if chances_for_chest.has(rarity):
			cumulative_chance += chances_for_chest[rarity]
			if rand_value <= cumulative_chance:
				return rarity
	return "common"

# MODIFIED: This function now receives the Sprite2D to animate
func _animate_item_drop(sprite: Sprite2D) -> void:
	print("DEBUG: --- Starting _animate_item_drop for sprite ID:", sprite.get_instance_id(), " ---")

	if _item_drop_tween and _item_drop_tween.is_valid() and _item_drop_tween.is_running():
		print("DEBUG: Killing existing _item_drop_tween.")
		_item_drop_tween.kill()
	_item_drop_tween = null

	var final_y_position = sprite.position.y # This is the target Y, (500, 300) from drop_random_image
	var initial_y_position = final_y_position - 150 # Start higher for drop effect

	sprite.position = Vector2(sprite.position.x, initial_y_position)
	sprite.scale = Vector2(0.1, 0.1) # Start small for animation
	sprite.modulate = Color(1, 1, 1, 0) # Start invisible
	print("DEBUG: _animate_item_drop: Sprite initial properties set: Position:", sprite.position, " Scale:", sprite.scale, " Modulate:", sprite.modulate)

	var texture_size = sprite.texture.get_size()
	var target_scale_vector: Vector2

	if texture_size == Vector2(16, 16):
		target_scale_vector = Vector2(12, 12)
		print("DEBUG: Texture size is 16x16, setting target scale to 12x12.")
	elif texture_size == Vector2(32, 32):
		target_scale_vector = Vector2(6, 6)
		print("DEBUG: Texture size is 32x32, setting target scale to 6x6.")
	else:
		target_scale_vector = Vector2(4, 4)
		print("DEBUG: Texture size is " + str(texture_size) + ", setting target scale to default 4x4.")

	_item_drop_tween = create_tween()
	_item_drop_tween.set_parallel(true)

	_item_drop_tween.tween_property(sprite, "position:y", final_y_position, 0.6) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
	
	_item_drop_tween.tween_property(sprite, "scale", target_scale_vector, 0.4) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		
	_item_drop_tween.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.3) \
		.set_ease(Tween.EASE_OUT)
	
	print("DEBUG: _animate_item_drop: Initial parallel tweens added with target scale:", target_scale_vector)

	await _item_drop_tween.finished
	print("DEBUG: _animate_item_drop: Initial drop animation finished.")

	var hover_subtween = create_tween()
	hover_subtween.tween_property(sprite, "position:y", final_y_position - 10, 0.8) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	hover_subtween.tween_property(sprite, "position:y", final_y_position, 0.8) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	hover_subtween.set_loops()
	hover_subtween.play()
	print("DEBUG: _animate_item_drop: Hover subtween started.")

	_item_drop_start_time = Time.get_unix_time_from_system()
	
	current_chest_state = ChestState.ITEM_DISPLAYED_WAITING_FOR_TAP
	%Label6.show()
	if not %text_anim.is_playing():
		%text_anim.play("tap_continue")    
	print("DEBUG: _animate_item_drop: Item fully displayed. State: ITEM_DISPLAYED_WAITING_FOR_TAP. Prompting user.")

	print("DEBUG: --- Exiting _animate_item_drop ---")

func get_color_for_rarity(rarity: String) -> Color:
	match rarity:
		"common": return Color("#FFFFFF")
		"rare": return Color("#64B5F6")
		"epic": return Color("#9C27B0")
		"legendary": return Color("#FFD700")
		_ : return Color("#FFFFFF")


func _on_equipment_button_pressed() -> void:
	var equipment_menu = load("res://game_menu.tscn")
	print("Loaded scene path:", equipment_menu.resource_path)
	get_tree().change_scene_to_packed(equipment_menu)


func _on_gift_button_pressed() -> void:
	pass # Replace with function body.
	# Open GIft Section ->
	# - Subscribe to our youtube
	# - Write comment to our videos
	# - Rate our game
	# - Follow our Tiktok


func _on_ad_button_pressed() -> void:
	if is_initialized:
		admob.load_rewarded_ad()
		await admob.rewarded_ad_loaded
		admob.show_rewarded_ad()


func _on_admob_initialization_completed(status_data: InitializationStatus) -> void:
	is_initialized = true


func _on_admob_rewarded_ad_user_earned_reward(ad_id: String, reward_data: RewardItem) -> void:
	Autoload.add_coins(earned_coins)
	Autoload.save_all_player_data()
