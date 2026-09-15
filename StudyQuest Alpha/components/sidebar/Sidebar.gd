extends PanelContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_btn_dashboard_button_down() -> void:
	get_tree().change_scene_to_file("res://scenes/dashboard/Dashboard.tscn")


func _on_btn_solo_button_down() -> void:
	get_tree().change_scene_to_file("res://scenes/solo/SoloSetup.tscn")


func _on_btn_multiplayer_button_down() -> void:
	pass # Replace with function body.


func _on_btn_question_bank_button_down() -> void:
	get_tree().change_scene_to_file("res://scenes/question_bank/QuestionBank.tscn")


func _on_btn_leaderboard_button_down() -> void:
	pass # Replace with function body.

func _on_btn_history_button_down() -> void:
	pass # Replace with function body.




func _on_btn_logout_button_down() -> void:
	get_tree().change_scene_to_file("res://scenes/login/Login.tscn")
