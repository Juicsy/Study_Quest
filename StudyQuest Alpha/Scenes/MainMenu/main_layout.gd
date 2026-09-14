extends Control

# Reference the placeholder node where scenes will load
@onready var content_panel: Panel = $HBoxContainer/ContentPanel

func _ready() -> void:
	change_content_scene("res://Scenes/MainMenu/1Home.tscn")
	
func change_content_scene(scene_path: String) -> void:
	# 1. Clear out the old scene currently inside the content panel
	for child in content_panel.get_children():
		child.queue_free()
	
	# 2. Load and instantiate the new scene
	var new_scene = load(scene_path).instantiate()
	
	# 3. Add it into the content panel
	content_panel.add_child(new_scene)

func _on_side_bar_home_pressed() -> void:
	change_content_scene("res://Scenes/MainMenu/1Home.tscn")

func _on_side_bar_flashcards_pressed() -> void:
	change_content_scene("res://Scenes/MainMenu/2Flashcards.tscn")

func _on_side_bar_question_bank_pressed() -> void:
	change_content_scene("res://Scenes/MainMenu/3QuestionBank.tscn")

func _on_side_bar_leaderboard_pressed() -> void:
	change_content_scene("res://Scenes/MainMenu/4Leaderboard.tscn")

func _on_side_bar_daily_quests_pressed() -> void:
	change_content_scene("res://Scenes/MainMenu/5DailyQuests.tscn")

func _on_side_bar_achievements_pressed() -> void:
	change_content_scene("res://Scenes/MainMenu/6Achievements.tscn")

func _on_side_bar_settings_pressed() -> void:
	change_content_scene("res://Scenes/MainMenu/7Settings.tscn")
