extends Control

func _on_btn_solo_button_down() -> void:
	get_tree().change_scene_to_file("res://scenes/solo/SoloSetup.tscn")
