# bullet_flamethrower.gd
extends Area2D

@onready var animated_sprite: AnimatedSprite2D = %AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = %CollisionShape2D
@onready var life_timer: Timer = Timer.new() # Create a new timer if not in scene

var damage: int = 0
var speed: int = 0
var range: int = 0
var direction: Vector2 = Vector2.ZERO

var current_distance: float = 0.0
var has_stopped_playing_animation = false # Flag to prevent multiple stop calls

func _ready():
	# Ensure the animated_sprite and collision_shape are properly assigned
	if not animated_sprite:
		animated_sprite = get_node_or_null("AnimatedSprite2D") # Adjust path if different
		if not animated_sprite:
			printerr("ERROR: AnimatedSprite2D not found on bullet_flamethrower!")
			queue_free()
			return
			
	if not collision_shape:
		collision_shape = get_node_or_null("CollisionShape2D") # Adjust path if different
		if not collision_shape:
			printerr("ERROR: CollisionShape2D not found on bullet_flamethrower!")
			queue_free()
			return

	# Add life_timer if not already present
	if not life_timer.is_connected("timeout", Callable(self, "_on_LifeTimer_timeout")):
		add_child(life_timer)
		life_timer.connect("timeout", Callable(self, "_on_LifeTimer_timeout"))

	animated_sprite.play("start") # Play the "start" animation
	# Connect to animation_finished to transition to 'stop' or queue_free
	animated_sprite.connect("animation_finished", Callable(self, "_on_AnimatedSprite_animation_finished"))
	
	print("DEBUG: Flamethrower bullet _ready. Playing 'start' animation.") # DEBUG

func setup_flame(dmg: int, spd: int, rng: int, dir: Vector2):
	damage = dmg
	speed = spd
	range = rng
	direction = dir.normalized() # Ensure normalized for consistent speed
	
	life_timer.wait_time = float(range) / speed if speed > 0 else 0.5 # Calculate life time, minimum 0.5s if speed is 0
	life_timer.start()
	print("DEBUG: Flamethrower bullet setup_flame. Damage: ", damage, ", Speed: ", speed, ", Range: ", range, ", Direction: ", direction, ", Lifetime: ", life_timer.wait_time, "s") # DEBUG


func _physics_process(delta):
	var move_amount = direction * speed * delta
	global_position += move_amount
	current_distance += move_amount.length()

	# REMOVED: This block is now handled by the life_timer
	# if current_distance >= range:
	#     print("DEBUG: Flamethrower bullet reached max range. Queueing free.") # DEBUG
	#     queue_free() # Remove if beyond range, or transition to 'stop' animation

func _on_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(damage)
		
	
	# For a flamethrower, individual 'bullets' usually don't disappear on hit
	# They persist for their full duration, dealing continuous damage.
	# If your bullet is designed to hit once and disappear, uncomment queue_free()
	# queue_free() 

func _on_area_entered(area):
	if area.has_method("take_damage"):
		area.take_damage(damage)
	# See comments in _on_body_entered regarding queue_free()


func _on_LifeTimer_timeout():
	# This is the primary point of removal for the bullet.
	# It ensures the 'stop' animation plays.
	if !has_stopped_playing_animation: # Prevent multiple calls if somehow triggered twice
		print("DEBUG: Flamethrower bullet LifeTimer timed out. Initiating stop sequence.") # DEBUG
		animated_sprite.play("stop") # Play "stop" animation
		has_stopped_playing_animation = true
		# The _on_AnimatedSprite_animation_finished will handle queue_free after "stop" animation
	else:
		print("DEBUG: LifeTimer timed out, but stop sequence already initiated.") # DEBUG


func _on_AnimatedSprite_animation_finished():
	if animated_sprite.animation == "stop":
		queue_free() # Remove the bullet after its 'stop' animation finishes
	elif animated_sprite.animation == "start":
		# If 'start' animation finishes, for a flamethrower, it should likely transition to a looping "on" animation.
		# Check your animated_sprite's animations. If you have a looping "fire" or "on" animation, play it here.
		# If "start" is the only animation and it's meant to loop for the duration, ensure it's set to loop.
		# If not, and you want continuous visuals, you'll need a "loop" animation.
		if animated_sprite: # Example of a looping animation
			animated_sprite.play("attack")
		
