# shotgun.gd
extends Area2D

@onready var shooting_point: Marker2D = %ShootingPoint
@onready var cooldown_timer:Timer = %CooldownTimer
@onready var reload_timer:Timer = %ReloadTimer
@onready var reload_bar:ProgressBar = %ProgressBar
@onready var reload_sound: AudioStreamPlayer = %ReloadSound
@onready var camera = get_tree().get_root().get_node("MainMap/player/Camera2D") # Adjust path!
var bullet_scene = preload("res://bullets/bullet_shotgun.tscn")
@onready var shoot_sound: AudioStreamPlayer = %ShootSound
# Removed player_node as we're not applying recoil to the player directly

var can_shoot := true
var is_reloading := false
var magazine := Autoload.shotgun_magazine
var spread_bullets := Autoload.shotgun_spread_bullets
var cooldown := Autoload.shotgun_cooldown
var reload_duration := Autoload.shotgun_reload_duration

# Recoil variables for the gun's sprite
var recoil_offset: Vector2 = Vector2.ZERO # Current visual offset due to recoil
var recoil_strength_visual: float = 25.0 # Shotgun has stronger recoil
var recoil_return_speed: float = 30.0 # Snappy return for shotgun

func _ready() -> void:
	%ProgressBar.hide()


func _physics_process(delta):
	# Handle recoil return
	if recoil_offset.length() > 0.1:
		recoil_offset = recoil_offset.move_toward(Vector2.ZERO, recoil_return_speed * delta)
	else:
		recoil_offset = Vector2.ZERO
	
	# Apply the recoil offset to the weapon's local position
	position = recoil_offset

	if is_reloading:
		return

	var enemies = get_overlapping_bodies()
	if enemies.is_empty():
		return

	var closest = enemies[0]
	for enemy in enemies:
		if global_position.distance_to(enemy.global_position) < global_position.distance_to(closest.global_position):
			closest = enemy

	look_at(closest.global_position)


func _unhandled_input(event):
	var screen_width = get_viewport_rect().size.x
	var shoot_side_left = Autoload.controls_flipped

	if is_reloading or not can_shoot:
		return

	if event is InputEventScreenTouch and event.pressed:
		var is_left = event.position.x < screen_width * 0.5
		if shoot_side_left != is_left:
			return # Tap is not on the shooting side

		if magazine > 0:
			shoot()
			magazine -= 1
			can_shoot = false
			cooldown_timer.start(cooldown)
			if magazine == 0:
				start_reload()


func shoot():
	for i in range(spread_bullets):
		var bullet = bullet_scene.instantiate()
		var spread_angle = deg_to_rad(randf_range(-15, 15))
		bullet.global_position = shooting_point.global_position
		bullet.rotation = shooting_point.global_rotation + spread_angle
		get_tree().current_scene.add_child(bullet)

	camera.shake(0.15, 8.0) # Screen shake method on Camera2D
	shoot_sound.play()
	
	_apply_recoil_visual() # Call the new visual recoil function


func _on_CooldownTimer_timeout():
	can_shoot = true
	%CooldownTimer.wait_time = Autoload.shotgun_cooldown


func start_reload():
	reload_bar.show()
	is_reloading = true
	reload_bar.visible = true
	reload_bar.value = 0
	reload_timer.start(reload_duration)
	reload_sound.play()


func _on_ReloadTimer_timeout():
	reload_bar.hide()
	reload_sound.stop()
	is_reloading = false
	magazine = Autoload.shotgun_magazine
	reload_bar.visible = false


func _process(delta):
	if is_reloading:
		reload_bar.value = reload_timer.time_left / reload_duration * 100.0

# --- Recoil Function for Gun Sprite ---
func _apply_recoil_visual():
	var local_recoil_direction = Vector2(-1, 0) # Points backwards in local space

	recoil_offset = local_recoil_direction * recoil_strength_visual
