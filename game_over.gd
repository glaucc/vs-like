extends CanvasLayer

@onready var revive_timer_label = %ReviveTimerLabel # Make sure this path is correct relative to GameOver node
@onready var revive_countdown_timer = %ReviveCountdownTimer # If this timer is a child of GameOver or accessible

func _ready():
	# Ensure this script and its node (GameOver) always process, even when the game is paused.
	set_process_mode(Node.PROCESS_MODE_ALWAYS)
	print("TRACE (GameOverScreen._ready): Set PROCESS_MODE_ALWAYS for GameOverScreen.")

func _process(delta):
	# This _process will run even when get_tree().paused is true because of PROCESS_MODE_ALWAYS.
	if is_visible(): # Only update if the game over screen is currently visible
		if revive_countdown_timer and revive_timer_label:
			var time_left = floor(revive_countdown_timer.time_left)
			if revive_countdown_timer.time_left > 0:
				revive_timer_label.text = "Reviving in: " + str(time_left) + "s"
				# print("DEBUG (GameOverScreen._process): Updating revive_timer_label to: ", revive_timer_label.text)
			else:
				# This condition is for when the timer has run out
				# You might want to get the actual life_token value from Autoload or Gameplay
				# For simplicity, let's assume Gameplay handles the "Game Over!" vs "Time's up!" final state.
				# If Gameplay.gd handles it, this can just show "Time's up!" and Gameplay will update it to "Game Over!"
				# when finalize_game_over is called.
				revive_timer_label.text = "Time's up!"
				# print("DEBUG (GameOverScreen._process): Timer ran out, setting revive_timer_label to 'Time's up!'.")
		else:
			print("ERROR (GameOverScreen._process): revive_countdown_timer or revive_timer_label is null!")
