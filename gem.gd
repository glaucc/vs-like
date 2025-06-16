extends Area2D

@export var score_value: int = 7
@export var gem_value: int = 1 # Define how much this gem is worth
@onready var collect_sound: AudioStreamPlayer = %CollectSound
@onready var gem_vfx: AnimatedSprite2D = %gem_vfx

func _on_body_entered(body: Node2D) -> void:
	if body.name == "player":
		Autoload.score += score_value
		body.collect_gem(gem_value)
		
		# 4. Detach sound and particles so they continue playing after the parent is freed.
		# This is CRUCIAL.
		if collect_sound:
			remove_child(collect_sound)
			get_tree().get_root().add_child(collect_sound) # Add to root of scene tree
		
		if gem_vfx:
			remove_child(gem_vfx)
			get_tree().get_root().add_child(gem_vfx)
		
		
		queue_free()
