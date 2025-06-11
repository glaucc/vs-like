# Camera.gd
extends Camera2D

var shake_strength := 0.0
var shake_decay := 5.0 # How fast the shake strength decays (higher = faster decay)
var max_offset_strength := 1.0 # Multiplier for the random offset, can adjust intensity without changing shake_strength

func shake(strength: float, duration: float = 0.2): # Added default duration for convenience
	# Only start a new shake if the incoming strength is higher, or if no shake is active
	if strength > shake_strength: # Or just always set, depending on desired behavior
		shake_strength = strength
	# Use a one-shot timer to stop the shake after a duration, allowing _process to decay it
	# No need to set shake_strength to 0 here; _process will handle the decay.
	# If you want it to completely stop after duration regardless of decay, you'd reset it here.
	# For a smooth decay, let _process handle it.
	get_tree().create_timer(duration, false).timeout.connect(func():
		shake_strength = 0.0
		offset = Vector2.ZERO # Ensure camera returns to origin after shake ends
	)


func _process(delta: float) -> void:
	if shake_strength > 0.0:
		# Apply random offset based on current shake strength
		offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake_strength * max_offset_strength

		# Decay the shake strength over time
		shake_strength = lerp(shake_strength, 0.0, delta * shake_decay)
		# Ensure shake_strength doesn't go below 0 due to lerp
		if shake_strength < 0.01: # Small threshold to prevent floating point issues
			shake_strength = 0.0
			offset = Vector2.ZERO # Reset offset once shake stops
	elif offset != Vector2.ZERO: # Catch-all to reset offset if shake_strength became 0 outside of timer
		offset = Vector2.ZERO
