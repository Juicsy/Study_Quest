extends Node

var selected_subject: String = "Math"
var selected_difficulty: String = "Easy"
var selected_mode: String = "Flashcards"
var requested_count: int = 10

var session_user_id: int = -1
var session_questions: Array[Dictionary] = []


func matching_questions(
	subject: String,
	difficulty: String
) -> Array[Dictionary]:
	var matches: Array[Dictionary] = []

	if MockAuth.current_user.is_empty():
		return matches

	for question in QuestionStore.questions:
		if not QuestionStore.can_view(question):
			continue
		if str(question["subject"]) != subject:
			continue
		if str(question["difficulty"]) != difficulty:
			continue

		matches.append(question.duplicate(true))

	return matches


func prepare_session() -> bool:
	session_questions.clear()
	session_user_id = -1

	var matches: Array[Dictionary] = matching_questions(
		selected_subject,
		selected_difficulty
	)

	if requested_count < 1 or requested_count > matches.size():
		return false

	matches.shuffle()

	for i in range(requested_count):
		var question: Dictionary = matches[i].duplicate(true)

		# Question Bank and Quiz currently use different type names.
		if question["type"] == "Multiple Choice":
			question["type"] = "MultipleChoice"

		session_questions.append(question)

	session_user_id = int(MockAuth.current_user["id"])
	return true


func get_questions(mode: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	if MockAuth.current_user.is_empty():
		return result
	if int(MockAuth.current_user["id"]) != session_user_id:
		return result
	if selected_mode != mode:
		return result

	for question in session_questions:
		result.append(question.duplicate(true))

	return result


func subject_label() -> String:
	return "%s • %s" % [selected_subject, selected_difficulty]


func reset_session() -> void:
	selected_subject = "Math"
	selected_difficulty = "Easy"
	selected_mode = "Flashcards"
	requested_count = 10
	session_user_id = -1
	session_questions.clear()
