extends Node

var has_result: bool = false
var score: int = 0
var correct_answers: int = 0
var total_questions: int = 0
var subject_text: String = ""


func store_result(
	final_score: int,
	correct: int,
	total: int,
	subject: String
) -> void:
	score = final_score
	total_questions = maxi(total, 0)
	correct_answers = clampi(correct, 0, total_questions)
	subject_text = subject
	has_result = true


func clear_result() -> void:
	has_result = false
	score = 0
	correct_answers = 0
	total_questions = 0
	subject_text = ""
