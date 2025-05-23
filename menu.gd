extends Node2D


func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://main_map.tscn");


func _on_achievements_button_pressed() -> void:
	%SoonLabel.show()
	%anims.play("soon_text")


func _on_settings_button_pressed() -> void:
	%SoonLabel.show()
	%anims.play("soon_text")


func _on_anims_animation_finished(anim_name: StringName) -> void:
	%SoonLabel.hide()


func _on_quit_button_pressed() -> void:
	get_tree().quit()
