# Rocket.gd (attached to bullet-rocket.tscn)
extends Area2D

@export var speed: float = 800.0 # How fast the rocket flies
@export var lifetime: float = 2.0 # How long the rocket exists before disappearing (or exploding)
@export var explosion_scene: PackedScene # Drag your 'explosion_rocket.tscn' here!

var velocity: Vector2 = Vector2.ZERO # Set by the RocketLauncher
var damage: int = 0 # This will be set by the RocketLauncher
var explosion_radius: float = 0.0 # This will be set by the RocketLauncher

var timer_started :bool= false # New variable to track if lifetime timer has started

func _ready() -> void:
	# DEBUG: Show initial state, which will be 0/0 because these are set AFTER _ready
	print("DEBUG: Rocket (bullet-rocket.tscn) _ready. Damage:", damage, " Radius:", explosion_radius, " Explosion Scene Set:", explosion_scene != null)
	
	body_entered.connect(_on_body_entered)
	set_process(true) # Ensure _physics_process is running

func _physics_process(delta: float) -> void:
	# Only start the lifetime timer and set rotation once velocity is actually set
	# (which happens after instantiation and RocketLauncher sets its properties)
	if not timer_started and velocity != Vector2.ZERO:
		var timer = get_tree().create_timer(lifetime)
		timer.timeout.connect(on_lifetime_end)
		timer_started = true
		print("DEBUG: Rocket lifetime timer started. Velocity received: ", velocity)
		
		# Make the rocket face its direction of travel once velocity is known
		rotation = velocity.angle()
		print("DEBUG: Rocket rotation set to: ", rad_to_deg(rotation), " degrees.")


	global_position += velocity * delta

func _on_body_entered(body: Node2D) -> void:
	print("DEBUG: Rocket (bullet-rocket.tscn) entered body: ", body.name, " type: ", body.get_class())
	
	if body.is_in_group("enemies"):
		print("DEBUG: Rocket hit an enemy! Exploding.")
		explode()
	elif body is StaticBody2D or body is TileMap:
		print("DEBUG: Rocket hit static environment! Exploding.")
		explode()
	elif body.is_in_group("player") or body.is_in_group("bullets"):
		print("DEBUG: Rocket hit friendly (player/bullet). Ignoring.")
		pass
	else:
		print("DEBUG: Rocket hit unhandled body. Exploding. Body:", body.name, " Type:", body.get_class())
		explode()

func on_lifetime_end() -> void:
	print("DEBUG: Rocket lifetime ended. Exploding.")
	explode()

func explode() -> void:
	print("DEBUG: Rocket.explode() called. Instantiating explosion.")
	if is_instance_valid(explosion_scene):
		var explosion_instance = explosion_scene.instantiate()
		get_parent().add_child(explosion_instance)
		explosion_instance.global_position = global_position
		
		if explosion_instance.has_method("setup_explosion"):
			print("DEBUG: Calling setup_explosion on instantiated explosion. Damage:", damage, " Radius:", explosion_radius)
			explosion_instance.setup_explosion(damage, explosion_radius)
		else:
			printerr("ERROR: Explosion scene '", explosion_scene.resource_path, "' is missing 'setup_explosion' method. Cannot pass damage!")
	else:
		printerr("ERROR: Rocket.explode() failed: explosion_scene is not valid or not set!")
	
	if Autoload.has_method("pool_manager") and Autoload.pool_manager.has_method("free_instance"):
		Autoload.pool_manager.free_instance("rocket_projectile", self)
	else:
		queue_free()
