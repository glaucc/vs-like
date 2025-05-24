extends Area2D

@onready var shooting_point: Marker2D = %ShootingPoint
@onready var cooldown_timer:Timer = %CooldownTimer
@onready var reload_timer:Timer = %ReloadTimer
@onready var reload_bar:ProgressBar = %ProgressBar
@onready var reload_sound: AudioStreamPlayer = %ReloadSound
@onready var camera = get_tree().get_root().get_node("MainMap/player/Camera2D") # Adjust path!
var bullet_scene = preload("res://bullets/bullet_shotgun.tscn")
@onready var shoot_sound: AudioStreamPlayer = %ShootSound


var can_shoot := true
var is_reloading := false
var magazine := Autoload.shotgun_magazine
var spread_bullets := Autoload.shotgun_spread_bullets
var cooldown := Autoload.shotgun_cooldown
var reload_duration := Autoload.shotgun_reload_duration


func _ready() -> void:
	%ProgressBar.hide()


func _physics_process(delta):
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
	if is_reloading or not can_shoot:
		return

	if event.is_action_pressed("shoot") and magazine > 0:
		shoot()
		magazine -= 1
		can_shoot = false
		cooldown_timer.start(cooldown)

		if magazine == 0:
			start_reload()


func shoot():

	for i in range(spread_bullets):
		var bullet = bullet_scene.instantiate()
		var spread_angle = deg_to_rad(randf_range(-15, 15))  # 15-degree spread
		bullet.global_position = shooting_point.global_position
		bullet.rotation = shooting_point.global_rotation + spread_angle
		get_tree().current_scene.add_child(bullet)

	camera.shake(0.15, 8.0)  # Screen shake method on Camera2D


func _on_CooldownTimer_timeout():
	can_shoot = true


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
