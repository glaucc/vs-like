extends CanvasLayer

@onready var kill: Button = %kill
@onready var add_xp: Button = %add_xp
@onready var _5_minutes: Button = %"+5minutes"
@onready var reset_health: Button = %reset_health


func _on_kill_pressed() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.health = 0
		player.emit_signal("health_depleted")


func _on_add_xp_pressed() -> void:
	Autoload.score += 100


func _on_minutes_pressed() -> void:
	var time = get_tree().get_first_node_in_group("MainMap")  # Or wherever the timer is
	if time:
		time.time_passed += 300.0


func _on_reset_health_pressed() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.health = player.max_health
		var bar = player.get_node("%ProgressBar")
		if bar:
			bar.value = player.health
