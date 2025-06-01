extends Control

var game_paused:bool = false


func _ready():
	# Load saved settings (if any)
	%FlipControlsCheckbox.button_pressed = Autoload.controls_flipped
	if Autoload.controls_flipped:
		%FlipControlsCheckbox.set_text("Flip Controls\n(Now: Move with Left, Shoot with Right)")
	else:
		%FlipControlsCheckbox.set_text("Flip Controls\n(Now: Move with Right, Shoot with Left)")
	
	%Vibration_toggle.button_pressed = Autoload.vibration_enabled
	%"HSlider-vib-duration".value = Autoload.vibration_duration_ms
	%"HSlider-vib-amplitude".value = Autoload.vibration_amplitude
	%"HSlider-vib-cooldown".value = Autoload.vibration_cooldown_sec


func _on_volume_value_changed(value: float) -> void:
	var db = linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(0, db)


func _on_check_box_toggled(toggled_on: bool) -> void:
	AudioServer.set_bus_mute(0,toggled_on)


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
		get_tree().paused = true
		%PauseMenu.show()
		game_paused = true
	elif Input.is_action_just_pressed("esc") and game_paused:
		get_tree().paused = false
		%PauseMenu.hide()
		game_paused = false
