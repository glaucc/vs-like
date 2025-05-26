extends Label

func _ready():
	# Optional: fade and float animation
	# This assumes you're using a Tween (or AnimationPlayer)
	# Add a simple fade + move up animation
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0, 0.5).set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(self, "position:y", position.y - 20, 0.5)
	tween.tween_callback(self.queue_free)
