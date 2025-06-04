extends Node2D


func _on_play_button_pressed() -> void:
	var main_map = load("res://main_map.tscn")
	print("Loaded scene path:", main_map.resource_path)
	get_tree().change_scene_to_packed(main_map)


func _on_achievements_button_pressed() -> void:
	%SoonLabel.show()
	%anims.play("soon_text")


func _on_settings_button_pressed() -> void:
	#%SoonLabel.show()
	#%anims.play("soon_text")
	var pause_scene = load("res://pause_menu.tscn")
	print("Loaded scene path:", pause_scene.resource_path)
	get_tree().change_scene_to_packed(pause_scene)
	


func _on_anims_animation_finished(anim_name: StringName) -> void:
	%SoonLabel.hide()


func _on_quit_button_pressed() -> void:
	get_tree().quit()
