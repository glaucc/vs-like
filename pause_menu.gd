extends Control

var game_paused:bool = false

@onready var volume_slider: HSlider = %Volume
@onready var mute_checkbox: CheckBox = %CheckBox

func _ready():
	# Load saved settings (if any)
	# These lines are good for other settings
	%FlipControlsCheckbox.button_pressed = Autoload.controls_flipped
	if Autoload.controls_flipped:
		%FlipControlsCheckbox.set_text("Flip Controls\n(Now: Move with Left, Shoot with Right)")
	else:
		%FlipControlsCheckbox.set_text("Flip Controls\n(Now: Move with Right, Shoot with Left)")

	%Vibration_toggle.button_pressed = Autoload.vibration_enabled
	%"HSlider-vib-duration".value = Autoload.vibration_duration_ms
	%"HSlider-vib-amplitude".value = Autoload.vibration_amplitude
	%"HSlider-vib-cooldown".value = Autoload.vibration_cooldown_sec

	# --- Crucial for Audio State ---
	# Initialize UI elements based on Autoload's loaded state
	# Autoload.volume stores the DESIRED unmuted volume
	volume_slider.value = Autoload.volume
	# Autoload.is_muted stores the current mute state
	mute_checkbox.button_pressed = Autoload.is_muted

	# Important: Autoload._ready should call apply_audio_settings()
	# to set the initial AudioServer state. So no need to do it here again.


func _on_volume_value_changed(value: float) -> void:
	# This function handles the slider changing value
	
	# Store the current value in Autoload.volume (the desired unmuted volume)
	Autoload.volume = value
	
	# If not currently muted, update previous_unmuted_volume
	# This makes sure that if you slide volume while unmuted, the "return" value is updated.
	if not Autoload.is_muted:
		Autoload.previous_unmuted_volume = value
	
	# Apply the volume to the AudioServer.
	# Note: If currently muted, Autoload.apply_audio_settings will handle setting 0db,
	# but for direct slider input, we apply the visible slider value.
	var db = linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(0, db)
	
	Autoload.save_settings()


func _on_check_box_toggled(toggled_on: bool) -> void:
	Autoload.is_muted = toggled_on # Update the Autoload's mute state
	AudioServer.set_bus_mute(0, toggled_on) # Apply mute to the AudioServer

	if toggled_on: # If muted
		# When muted, visually set the slider to 0, but DON'T change Autoload.volume.
		# Autoload.volume should retain its desired unmuted value.
		volume_slider.value = 0
		
		# Save current Autoload.volume into previous_unmuted_volume before muting.
		# This line is important if _on_volume_value_changed isn't always called before mute.
		# However, if volume_slider.value is always synced to Autoload.volume, and
		# _on_volume_value_changed updates previous_unmuted_volume, this might be redundant,
		# but it's safer to ensure it.
		# Autoload.previous_unmuted_volume = Autoload.volume # Uncomment if needed for robustness
		
	else: # If unmuted
		# Restore the volume to what it was before muting
		Autoload.volume = Autoload.previous_unmuted_volume
		
		# Apply this restored volume to the AudioServer
		var db = linear_to_db(Autoload.volume / 100.0)
		AudioServer.set_bus_volume_db(0, db)
		
		# Update the slider to reflect the restored volume
		volume_slider.value = Autoload.volume

	Autoload.save_settings() # Save the new mute state (and potentially restored volume)


func _on_flip_controls_checkbox_pressed() -> void:
	Autoload.controls_flipped = !Autoload.controls_flipped
	if Autoload.controls_flipped:
		%FlipControlsCheckbox.set_text("Flip Controls
(Now: Move with Left, Shoot with Right)")
	else:
		%FlipControlsCheckbox.set_text("Flip Controls
(Now: Move with Right, Shoot with Left)")
	Autoload.save_settings()


func _on_VibrationToggle_toggled(button_pressed):
	Autoload.vibration_enabled = button_pressed
	Autoload.save_settings()

func _on_DurationSlider_value_changed(value):
	Autoload.vibration_duration_ms = int(value)
	Autoload.save_settings()

func _on_AmplitudeSlider_value_changed(value):
	Autoload.vibration_amplitude = value
	Autoload.save_settings()

func _on_CooldownSlider_value_changed(value):
	Autoload.vibration_cooldown_sec = value
	Autoload.save_settings()


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("esc") and !game_paused:
		Autoload.pause_menu_opened = true
		%PauseMenuMusicPlayer.play()
		%GameMusicPlayer.stop()
		
		#emit_signal("play_sfx", "ui_pause") # Play pause sound
		
		get_tree().paused = true
		%PauseMenu.show()
		game_paused = true
	elif Input.is_action_just_pressed("esc") and game_paused:
		Autoload.pause_menu_opened = false
		%PauseMenuMusicPlayer.stop()
		%GameMusicPlayer.play()
		var audio_stream = load("res://assets/SFX/unpause.ogg")
		%SFXPlayer.set_stream(audio_stream)
		%SFXPlayer.play()
		
		get_tree().paused = false
		%PauseMenu.hide()
		game_paused = false
