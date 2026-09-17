extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_btn_quiz_button_down() -> void:
	get_tree().change_scene_to_file("res://Scenes/gameplay/quiz/Quiz.tscn")


func _on_btn_flashcards_button_down() -> void:
	get_tree().change_scene_to_file("res://Scenes/gameplay/flashcards/Flashcards.tscn")


func _on_btn_back_button_down() -> void:
	get_tree().change_scene_to_file("res://Scenes/dashboard/Dashboard.tscn")
