extends Control


func _on_left_button_pressed() -> void:
	%ui_anims.play("soon_text")


func _on_right_button_pressed() -> void:
	%ui_anims.play("soon_text")



func _on_ui_anims_animation_finished(anim_name: StringName) -> void:
	if anim_name == "menu-idle":
		%ui_anims.play("menu-idle")

func _physics_process(delta: float) -> void:
	if !%ui_anims.is_playing():
		%ui_anims.play("menu-idle")
