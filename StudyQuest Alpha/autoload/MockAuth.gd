extends Node

var current_user: Dictionary = {}
var pending_username: String = ""

# ID 2 is reserved for QuestionStore's sample author.
var next_user_id: int = 3

var users: Array[Dictionary] = [
	{
		"id": 1,
		"first_name": "Test",
		"last_name": "User",
		"username": "test",
		"email": "test@example.com",
		"password": "123"
	}
]


# Returns an empty string on success, otherwise an error message.
func register_user(
	first_name: String,
	last_name: String,
	username: String,
	email: String,
	password: String,
	confirmation: String
) -> String:
	first_name = first_name.strip_edges()
	last_name = last_name.strip_edges()
	username = username.strip_edges()
	email = email.strip_edges().to_lower()

	if (
		first_name.is_empty()
		or last_name.is_empty()
		or username.is_empty()
		or email.is_empty()
		or password.strip_edges().is_empty()
		or confirmation.is_empty()
	):
		return "Please complete all fields."

	var username_pattern := RegEx.new()
	username_pattern.compile("^[A-Za-z0-9_]{3,24}$")

	if username_pattern.search(username) == null:
		return "Username: use 3–24 letters, numbers, or underscores."

	# Basic format check, not email verification.
	var email_pattern := RegEx.new()
	email_pattern.compile("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$")

	if email_pattern.search(email) == null:
		return "Please enter a valid email format."

	if password.length() < 8:
		return "Use at least 8 characters for your password."

	if password != confirmation:
		return "Passwords do not match."

	for user in users:
		if str(user["username"]).to_lower() == username.to_lower():
			return "That username is already taken."

		if str(user["email"]).to_lower() == email:
			return "That email is already registered."

	users.append({
		"id": next_user_id,
		"first_name": first_name,
		"last_name": last_name,
		"username": username,
		"email": email,
		"password": password
	})

	next_user_id += 1
	pending_username = username
	return ""


func login(username: String, password: String) -> bool:
	current_user.clear()
	var normalized_username: String = username.strip_edges().to_lower()

	for user in users:
		if (
			str(user["username"]).to_lower() == normalized_username
			and str(user["password"]) == password
		):
			current_user = user.duplicate(true)
			current_user.erase("password")
			return true

	return false


func logout() -> void:
	current_user.clear()
