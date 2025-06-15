# RocketLauncher.gd
extends Node2D

@onready var shooting_point: Marker2D = %ShootingPoint
@onready var cooldown_timer: Timer = %CooldownTimer
@onready var reload_timer: Timer = %ReloadTimer
@onready var reload_bar: ProgressBar = %ProgressBar
@onready var reload_sound: AudioStreamPlayer = %ReloadSound
@onready var shoot_sound: AudioStreamPlayer = %ShootSound
@onready var camera = get_tree().get_root().get_node("MainMap/player/Camera2D")

@export var rocket_scene: PackedScene # Drag your bullet-rocket.tscn here in the editor
@export var rocket_speed: float = 800.0

var can_fire := true
var is_reloading := false
var current_magazine_rockets: int
var fire_cooldown: float
var current_reload_duration: float

var current_damage: int = 0
var current_explosion_size: float = 0.0

var recoil_offset: Vector2 = Vector2.ZERO
var recoil_strength_visual: float = 20.0
var recoil_return_speed: float = 25.0

func _ready() -> void:
	if not rocket_scene:
		printerr("RocketLauncher: 'rocket_scene' (bullet-rocket.tscn) is not set! Please assign it in the editor.")
	if not shooting_point:
		printerr("RocketLauncher: 'ShootingPoint' Marker2D is missing! Add one as a child.")
	if not camera:
		printerr("RocketLauncher: Camera2D not found at 'MainMap/player/Camera2D'. Adjust path if necessary.")

	%ProgressBar.hide()

	cooldown_timer.timeout.connect(_on_CooldownTimer_timeout)
	reload_timer.timeout.connect(_on_ReloadTimer_timeout)
	
	cooldown_timer.set_one_shot(false)
	cooldown_timer.start()
	
	

	_update_stats_from_autoload()


func _physics_process(delta: float) -> void:
	if recoil_offset.length() > 0.1:
		recoil_offset = recoil_offset.move_toward(Vector2.ZERO, recoil_return_speed * delta)
	else:
		recoil_offset = Vector2.ZERO
	position = recoil_offset

	if is_reloading:
		return

	var target_enemy: CharacterBody2D = null
	var min_distance: float = INF

	for node in get_tree().get_nodes_in_group("enemies"):
		if node is CharacterBody2D:
			var distance = global_position.distance_to(node.global_position)
			if distance < min_distance:
				min_distance = distance
				target_enemy = node
	
	if target_enemy:
		look_at(target_enemy.global_position)
		if cooldown_timer.is_stopped() and can_fire and not is_reloading:
			cooldown_timer.start(fire_cooldown)
	else:
		cooldown_timer.stop()
	
	current_explosion_size = 100.0


func fire() -> void:
	if not Autoload.rocket_active or is_reloading or current_magazine_rockets <= 0:
		print("DEBUG: RocketLauncher.fire() blocked. Active:", Autoload.rocket_active, " Reloading:", is_reloading, " Ammo:", current_magazine_rockets)
		return

	if not rocket_scene or not shooting_point:
		printerr("DEBUG: RocketLauncher.fire() failed: rocket_scene or shooting_point not set.")
		return

	var rocket_instance: Area2D
	if Autoload.has_method("pool_manager") and Autoload.pool_manager.has_method("spawn_pool"):
		rocket_instance = Autoload.pool_manager.spawn_pool("rocket_projectile")
		if rocket_instance:
			rocket_instance.set_process_mode(Node.PROCESS_MODE_INHERIT)
			rocket_instance.global_position = shooting_point.global_position
			var direction = Vector2(1, 0).rotated(global_rotation)
			rocket_instance.velocity = direction * rocket_speed
			rocket_instance.damage = current_damage
			rocket_instance.explosion_radius = current_explosion_size
			get_tree().current_scene.add_child(rocket_instance)
	else:
		rocket_instance = rocket_scene.instantiate()
		get_tree().current_scene.add_child(rocket_instance)
		rocket_instance.global_position = shooting_point.global_position
		var direction = Vector2(1, 0).rotated(global_rotation)
		rocket_instance.velocity = direction * rocket_speed
		rocket_instance.damage = current_damage
		rocket_instance.explosion_radius = current_explosion_size

	# DEBUG: Confirm values passed to rocket_instance
	print("DEBUG: RocketLauncher firing. Rocket instance created.")
	print("DEBUG:    Rocket velocity: ", rocket_instance.velocity)
	print("DEBUG:    Rocket damage (from launcher): ", rocket_instance.damage)
	print("DEBUG:    Rocket explosion_radius (from launcher): ", rocket_instance.explosion_radius)


	current_magazine_rockets -= 1
	
	camera.shake(0.2, 10.0)
	shoot_sound.play()
	_apply_recoil_visual()

	print("RocketLauncher: Fired a rocket! Ammo left: ", current_magazine_rockets)
	
	if current_magazine_rockets == 0:
		start_reload()


func _on_CooldownTimer_timeout() -> void:
	print("DEBUG: CooldownTimer timed out. Attempting to fire...")
	if can_fire and not is_reloading and current_magazine_rockets > 0:
		fire()
	else:
		print("DEBUG: Fire condition not met: can_fire=", can_fire, " is_reloading=", is_reloading, " ammo=", current_magazine_rockets)


func start_reload() -> void:
	if is_reloading: return

	reload_bar.show()
	is_reloading = true
	reload_bar.value = 0
	reload_timer.start(current_reload_duration)
	reload_sound.play()
	print("RocketLauncher: Starting reload...")

func _on_ReloadTimer_timeout() -> void:
	reload_bar.hide()
	reload_sound.stop()
	is_reloading = false
	current_magazine_rockets = Autoload.rocket_magazine_size
	print("RocketLauncher: Reload complete. Ammo: ", current_magazine_rockets)

func _process(delta: float) -> void:
	if is_reloading:
		reload_bar.value = (current_reload_duration - reload_timer.time_left) / current_reload_duration * 100.0

func _update_stats_from_autoload() -> void:
	current_damage = Autoload.rocket_base_damage
	#current_explosion_size = Autoload.explosion_size
	current_explosion_size = 100.0
	fire_cooldown = Autoload.player_attack_speed
	current_reload_duration = Autoload.rocket_reload_duration
	
	if not is_reloading:
		current_magazine_rockets = Autoload.rocket_magazine_size
	
	cooldown_timer.wait_time = fire_cooldown

	print("DEBUG: RocketLauncher: Stats updated from Autoload. Damage: %d, Explosion: %f, Cooldown: %f, Reload: %f, Magazine: %d" % [current_damage, current_explosion_size, fire_cooldown, current_reload_duration, current_magazine_rockets])

func _apply_recoil_visual() -> void:
	var local_recoil_direction = Vector2(-1, 0)
	recoil_offset = local_recoil_direction * recoil_strength_visual
