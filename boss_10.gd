extends CharacterBody2D

var health = 1000

@onready var player = get_node("/root/MainMap/player")

func _ready() -> void:
	pass #play walk animation


func _physics_process(delta: float) -> void:
	var level = Autoload.level
	var enemy_speed = 200
	
	var direction = global_position.direction_to(player.global_position)
	velocity= direction * 600.0 * level * enemy_speed
	move_and_slide()


func take_damage():
	health -= 50
	#play hurt animation
	
	if health <= 0:
		queue_free()
		Autoload.score += 10000
		
		
		const SMOKE_EXPLOSION = preload("res://smoke_explosion/smoke_explosion.tscn")
		var smoke = SMOKE_EXPLOSION.instantiate()
		get_parent().add_child(smoke)
		smoke.global_position = global_position
	
	
