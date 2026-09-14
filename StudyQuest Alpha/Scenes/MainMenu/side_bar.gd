extends Control

signal Home_pressed
signal Flashcards_pressed
signal QuestionBank_pressed
signal Leaderboard_pressed
signal DailyQuests_pressed
signal Achievements_pressed
signal Settings_pressed

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_home_pressed() -> void:
	Home_pressed.emit()


func _on_flashcards_pressed() -> void:
	Flashcards_pressed.emit()


func _on_question_bank_pressed() -> void:
	QuestionBank_pressed.emit()


func _on_leaderboard_pressed() -> void:
	Leaderboard_pressed.emit()


func _on_DailyQuests_pressed() -> void:
	DailyQuests_pressed.emit()


func _on_achievements_pressed() -> void:
	Achievements_pressed.emit()


func _on_settings_pressed() -> void:
	Settings_pressed.emit()
