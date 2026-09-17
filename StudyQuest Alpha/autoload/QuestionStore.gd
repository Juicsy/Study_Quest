extends Node

const SUBJECTS = ["Math", "Science", "English", "ESP"]
const DIFFICULTIES = ["Easy", "Medium", "Hard"]
const TYPES = ["Multiple Choice", "Identification"]
const VISIBILITIES = ["Private", "Public", "Team-only"]

# Temporary demo identity, not connected to Login yet.
var current_user_id: int = 1
var teams: Array[Dictionary] = [
	{"id": 1, "name": "Study Quest Demo Team"}
]

var editing_id: int = -1
var selected_id: int = -1
var next_id: int = 4

var questions: Array[Dictionary] = [
	{
		"id": 1,
		"owner_id": 1,
		"creator": "You",
		"subject": "Math",
		"difficulty": "Easy",
		"type": "Multiple Choice",
		"visibility": "Private",
		"team_id": -1,
		"question": "What is the derivative of x²?",
		"choices": ["x", "2x", "x²", "2"],
		"correct_index": 1,
		"answer": "2x"
	},
	{
		"id": 2,
		"owner_id": 2,
		"creator": "Demo Author",
		"subject": "Science",
		"difficulty": "Easy",
		"type": "Identification",
		"visibility": "Public",
		"team_id": -1,
		"question": "Which planet is known as the Red Planet?",
		"choices": [],
		"correct_index": -1,
		"answer": "Mars"
	},
	{
		"id": 3,
		"owner_id": 1,
		"creator": "You",
		"subject": "English",
		"difficulty": "Medium",
		"type": "Identification",
		"visibility": "Team-only",
		"team_id": 1,
		"question": "Identify the figure of speech: Time is a thief.",
		"choices": [],
		"correct_index": -1,
		"answer": "Metaphor"
	}
]


func belongs_to_team(team_id: int) -> bool:
	for team in teams:
		if int(team["id"]) == team_id:
			return true
	return false


func can_view(question: Dictionary) -> bool:
	return (
		int(question["owner_id"]) == current_user_id
		or question["visibility"] == "Public"
		or (
			question["visibility"] == "Team-only"
			and belongs_to_team(int(question["team_id"]))
		)
	)


func get_question(id: int) -> Dictionary:
	for question in questions:
		if int(question["id"]) == id and can_view(question):
			return question.duplicate(true)
	return {}


func can_edit(id: int) -> bool:
	var question: Dictionary = get_question(id)
	return (
		not question.is_empty()
		and int(question["owner_id"]) == current_user_id
	)


func save_question(data: Dictionary, id: int = -1) -> int:
	var copy: Dictionary = data.duplicate(true)

	if copy["visibility"] == "Team-only":
		if not belongs_to_team(int(copy["team_id"])):
			return -1

	if id == -1:
		copy["id"] = next_id
		copy["owner_id"] = current_user_id
		copy["creator"] = str(MockAuth.current_user.get("username", "Unknown"))
		next_id += 1
		questions.append(copy)
	else:
		if not can_edit(id):
			return -1

		for i in range(questions.size()):
			if int(questions[i]["id"]) == id:
				copy["id"] = id
				copy["owner_id"] = questions[i]["owner_id"]
				copy["creator"] = questions[i]["creator"]
				questions[i] = copy
				break

	selected_id = int(copy["id"])
	return selected_id


func delete_question(id: int) -> bool:
	if not can_edit(id):
		return false

	for i in range(questions.size()):
		if int(questions[i]["id"]) == id:
			questions.remove_at(i)
			if selected_id == id:
				selected_id = -1
			return true

	return false

func get_creator_name(question: Dictionary) -> String:
	var owner_id: int = int(question["owner_id"])

	for user in MockAuth.users:
		if int(user["id"]) == owner_id:
			return str(user["username"])

	# Handles the sample author who has no login account.
	var fallback: String = str(question.get("creator", "Unknown"))
	return "Unknown" if fallback == "You" else fallback
