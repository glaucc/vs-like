# flamethrower.gd
extends Area2D

@onready var shooting_point: Marker2D = %ShootingPoint
@onready var reload_timer: Timer = %ReloadTimer
@onready var reload_bar: ProgressBar = %ProgressBar
@onready var reload_sound: AudioStreamPlayer = %ReloadSound
@onready var camera = %Camera2D
var bullet_scene = preload("res://bullets/bullet-flamethrower.tscn")
@onready var shoot_sound: AudioStreamPlayer = %ShootSound

# Preload flamethrower sound variations
var flamethrower_sound_short = preload("res://assets/SFX/flamethrower/flamethrower-short.ogg")
var flamethrower_sound_medium = preload("res://assets/SFX/flamethrower/flamethrower-medium.ogg")
var flamethrower_sound_long = preload("res://assets/SFX/flamethrower/flamethrower-long.ogg")

var can_shoot := true
var is_reloading := false
var current_magazine_time: float = 0.0

# Flamethrower specific stats from Autoload
var base_damage: int
var magazine_duration: float
var fire_range: int
var bullet_speed: int
var reload_duration: float

# Upgrade levels for flamethrower direction
enum FireMode { SINGLE_RIGHT, BOTH_SIDES, FOUR_SIDES }
var current_fire_mode: FireMode = FireMode.SINGLE_RIGHT # Initial mode

# Recoil variables for the gun's sprite
var recoil_offset: Vector2 = Vector2.ZERO
var recoil_strength_visual: float = 10.0
var recoil_return_speed: float = 20.0

func _ready() -> void:
	%ProgressBar.hide()
	_update_stats_from_autoload()

	# Initialize magazine duration from the short sound's length, or from Autoload if applicable
	# If magazine_duration should be a fixed stat from Autoload, uncomment the line below
	# magazine_duration = Autoload.flamethrower_magazine_duration # Example if this exists
	set_flamethrower_sound_and_duration(flamethrower_sound_short)
	current_magazine_time = magazine_duration
	print("Flamethrower initialized. Magazine Duration: ", magazine_duration, "s") # DEBUG

func _update_stats_from_autoload():
	base_damage = Autoload.flamethrower_base_damage
	fire_range = Autoload.flamethrower_bullet_range
	bullet_speed = Autoload.flamethrower_bullet_speed
	reload_duration = Autoload.flamethrower_reload_duration

	reload_timer.wait_time = reload_duration
	print("Flamethrower stats updated from Autoload. Base Damage: ", base_damage, ", Range: ", fire_range) # DEBUG

func set_flamethrower_sound_and_duration(sound_stream: AudioStream):
	shoot_sound.stream = sound_stream
	if sound_stream:
		# If magazine duration is determined by sound length
		magazine_duration = sound_stream.get_length()
		# If magazine duration is a fixed stat from Autoload, ensure it's not overwritten here unless intended
		# e.g., if sound length is just for audio, and mag duration is a gameplay stat
	else:
		magazine_duration = 0.0

	current_magazine_time = magazine_duration # Reset magazine when sound/duration changes
	print("Flamethrower sound changed to: ", sound_stream.resource_path.get_file() if sound_stream else "None", ". New Magazine Duration: ", magazine_duration, "s") # DEBUG

func _physics_process(delta: float) -> void:
	# Handle recoil return
	if recoil_offset.length() > 0.1:
		recoil_offset = recoil_offset.move_toward(Vector2.ZERO, recoil_return_speed * delta)
	else:
		recoil_offset = Vector2.ZERO

	# Apply the recoil offset to the weapon's local position
	# Consider applying this to a child Node2D or Sprite2D for better modularity
	position = recoil_offset

	if is_reloading:
		return

	# Shoot if conditions are met
	if can_shoot and current_magazine_time > 0:
		shoot(delta)
	elif current_magazine_time <= 0 and not is_reloading:
		start_reload()
		print("Flamethrower magazine empty. Starting reload.") # DEBUG

func shoot(delta: float):
	if not can_shoot or is_reloading:
		print("DEBUG: Cannot shoot (can_shoot: ", can_shoot, ", is_reloading: ", is_reloading, ")") # DEBUG
		return

	current_magazine_time -= delta
	if current_magazine_time <= 0:
		stop_shooting()
		start_reload()
		print("DEBUG: Magazine ran out during shoot. Stopping and reloading.") # DEBUG
		return

	if not shoot_sound.playing:
		shoot_sound.play()
		print("DEBUG: Flamethrower shoot sound started.") # DEBUG

	_emit_flames()
	_apply_recoil_visual()
	camera.shake(0.05, 5.0)

func _emit_flames():
	# Assuming WeaponPivot's rotation dictates the "forward" of the gun.
	var base_forward_direction = Vector2.RIGHT.rotated(global_rotation)
	var spread_angle_deg = randf_range(-5.0, 5.0) # Small natural spread

	match current_fire_mode:
		FireMode.SINGLE_RIGHT:
			var flame = bullet_scene.instantiate()
			get_tree().current_scene.add_child(flame)
			flame.global_position = shooting_point.global_position
			flame.setup_flame(base_damage, bullet_speed, fire_range, base_forward_direction.rotated(deg_to_rad(spread_angle_deg)))
			print("DEBUG: Emitted SINGLE_RIGHT flame. Pos: ", flame.global_position, ", Dir: ", base_forward_direction.rotated(deg_to_rad(spread_angle_deg))) # DEBUG

		FireMode.BOTH_SIDES:
			var flame_forward = bullet_scene.instantiate()
			get_tree().current_scene.add_child(flame_forward)
			flame_forward.global_position = shooting_point.global_position
			flame_forward.setup_flame(base_damage, bullet_speed, fire_range, base_forward_direction.rotated(deg_to_rad(spread_angle_deg)))
			print("DEBUG: Emitted BOTH_SIDES (forward) flame. Pos: ", flame_forward.global_position) # DEBUG

			var flame_backward = bullet_scene.instantiate()
			get_tree().current_scene.add_child(flame_backward)
			flame_backward.global_position = shooting_point.global_position
			flame_backward.setup_flame(base_damage, bullet_speed, fire_range, base_forward_direction.rotated(deg_to_rad(180) + deg_to_rad(spread_angle_deg)))
			print("DEBUG: Emitted BOTH_SIDES (backward) flame. Pos: ", flame_backward.global_position) # DEBUG

		FireMode.FOUR_SIDES:
			# Emitting flames in global cardinal directions (Right, Left, Down, Up)
			# If these should be relative to weapon's rotation, adjust the vectors.
			var flame_right = bullet_scene.instantiate()
			get_tree().current_scene.add_child(flame_right)
			flame_right.global_position = shooting_point.global_position
			flame_right.setup_flame(base_damage, bullet_speed, fire_range, Vector2.RIGHT.rotated(deg_to_rad(spread_angle_deg)))
			print("DEBUG: Emitted FOUR_SIDES (right) flame. Pos: ", flame_right.global_position) # DEBUG

			var flame_left = bullet_scene.instantiate()
			get_tree().current_scene.add_child(flame_left)
			flame_left.global_position = shooting_point.global_position
			flame_left.setup_flame(base_damage, bullet_speed, fire_range, Vector2.LEFT.rotated(deg_to_rad(spread_angle_deg)))
			print("DEBUG: Emitted FOUR_SIDES (left) flame. Pos: ", flame_left.global_position) # DEBUG

			var flame_down = bullet_scene.instantiate()
			get_tree().current_scene.add_child(flame_down)
			flame_down.global_position = shooting_point.global_position
			flame_down.setup_flame(base_damage, bullet_speed, fire_range, Vector2.DOWN.rotated(deg_to_rad(spread_angle_deg)))
			print("DEBUG: Emitted FOUR_SIDES (down) flame. Pos: ", flame_down.global_position) # DEBUG

			var flame_up = bullet_scene.instantiate()
			get_tree().current_scene.add_child(flame_up)
			flame_up.global_position = shooting_point.global_position
			flame_up.setup_flame(base_damage, bullet_speed, fire_range, Vector2.UP.rotated(deg_to_rad(spread_angle_deg)))
			print("DEBUG: Emitted FOUR_SIDES (up) flame. Pos: ", flame_up.global_position) # DEBUG

func stop_shooting():
	if shoot_sound.playing:
		shoot_sound.stop()
		print("DEBUG: Flamethrower shoot sound stopped.") # DEBUG
	else:
		print("DEBUG: Flamethrower shoot sound already stopped.") # DEBUG

func start_reload():
	if is_reloading:
		print("DEBUG: Already reloading. Skipping start_reload.") # DEBUG
		return

	%ProgressBar.show()
	is_reloading = true
	reload_bar.value = 0 # Start progress bar at 0
	reload_bar.max_value = reload_duration # Set max value to reload duration for easier calculation
	reload_timer.start(reload_duration)
	reload_sound.play()
	stop_shooting() # Ensure shooting sound stops when reloading starts
	can_shoot = false # Prevent shooting during reload
	print("DEBUG: Reload started. Duration: ", reload_duration, "s") # DEBUG

func _on_ReloadTimer_timeout():
	reload_bar.hide()
	reload_sound.stop()
	is_reloading = false
	current_magazine_time = magazine_duration # Refill magazine
	can_shoot = true # Allow shooting again
	print("DEBUG: Reload finished. Magazine refilled.") # DEBUG

func _process(delta):
	# Update reload bar during active reload
	if is_reloading:
		reload_bar.value = reload_duration - reload_timer.time_left
		# If reload_bar.max_value is 100, use:
		# reload_bar.value = (reload_duration - reload_timer.time_left) / reload_duration * 100.0
	# Hide the bar if not reloading and magazine is full or not shooting
	# Removed the magazine level display from the reload bar for clarity.
	# If you need a magazine level display, consider a separate ProgressBar.
	elif reload_bar.visible and not is_reloading:
		reload_bar.hide()

func _apply_recoil_visual():
	var local_recoil_direction = Vector2(-2, 0)
	recoil_offset = local_recoil_direction * recoil_strength_visual

func upgrade_fire_mode(new_mode: FireMode):
	current_fire_mode = new_mode

func upgrade_flamethrower_duration(duration_type: String):
	match duration_type:
		"short":
			set_flamethrower_sound_and_duration(flamethrower_sound_short)
			print("short sound")
		"medium":
			set_flamethrower_sound_and_duration(flamethrower_sound_medium)
			print("medium sound")
		"long":
			set_flamethrower_sound_and_duration(flamethrower_sound_long)
			print("long sound")
		_:
			printerr("Invalid flamethrower duration type: ", duration_type)
			print("ERROR: Invalid flamethrower duration type: ", duration_type) # DEBUG
