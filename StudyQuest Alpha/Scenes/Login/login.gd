extends Control

const DASHBOARD_PATH: String = "res://scenes/dashboard/Dashboard.tscn"
const REGISTER_PATH: String = "res://scenes/register/Register.tscn"

@onready var layout: VBoxContainer = $ScreenMargin/CenterLayout/LoginPanel/LoginMargin/LoginLayout

@onready var txt_username: LineEdit = layout.get_node(
	"UsernameSection/txtUsername"
)
@onready var txt_password: LineEdit = layout.get_node(
	"PasswordSection/txtPassword"
)
@onready var lbl_error: Label = layout.get_node("lblError")
@onready var show_password: CheckBox = layout.get_node(
	"PasswordSection/chkShowPassword"
)

var navigating: bool = false


func _ready() -> void:
	# Returning to Login ends the previous session.
	MockAuth.logout()
	QuestionStore.current_user_id = -1
	QuestionStore.teams.clear()
	QuestionStore.selected_id = -1
	QuestionStore.editing_id = -1
	QuizSession.clear_result()
	StudySession.reset_session()
	
	lbl_error.text = ""
	txt_password.clear()
	show_password.set_pressed_no_signal(false)
	txt_password.secret = true

	connect_once(
		show_password.toggled,
		_on_chk_show_password_toggled
	)
	connect_once(
		layout.get_node("btnLogin").pressed,
		_on_btn_login_pressed
	)
	connect_once(
		layout.get_node("RegisterSection/btnRegister").pressed,
		_on_btn_register_pressed
	)
	connect_once(
		txt_username.text_submitted,
		_on_txt_username_text_submitted
	)
	connect_once(
		txt_password.text_submitted,
		_on_txt_password_text_submitted
	)

	if not MockAuth.pending_username.is_empty():
		txt_username.text = MockAuth.pending_username
		MockAuth.pending_username = ""
		txt_password.grab_focus()
	else:
		txt_username.grab_focus()


func connect_once(event: Signal, handler: Callable) -> void:
	if not event.is_connected(handler):
		event.connect(handler)


func _on_chk_show_password_toggled(toggled_on: bool) -> void:
	txt_password.secret = not toggled_on


func _on_btn_login_pressed() -> void:
	if navigating:
		return

	lbl_error.text = ""

	if (
		txt_username.text.strip_edges().is_empty()
		or txt_password.text.is_empty()
	):
		lbl_error.text = "Enter your username and password."
		return

	if not MockAuth.login(txt_username.text, txt_password.text):
		lbl_error.text = "Incorrect username or password."
		return

	open_dashboard()


func open_dashboard() -> void:
	# Give Question Bank the signed-in user's identity.
	var user_id: int = int(MockAuth.current_user["id"])
	QuestionStore.current_user_id = user_id
	QuestionStore.selected_id = -1
	QuestionStore.editing_id = -1

	# Only the original test account belongs to the demo team.
	QuestionStore.teams.clear()
	if user_id == 1:
		QuestionStore.teams.append({
			"id": 1,
			"name": "Study Quest Demo Team"
		})

	navigating = true
	var error := get_tree().change_scene_to_file(DASHBOARD_PATH)

	if error != OK:
		navigating = false
		MockAuth.logout()
		QuestionStore.current_user_id = -1
		QuestionStore.teams.clear()
		lbl_error.text = "Could not open Dashboard. Check its scene path."


func _on_btn_register_pressed() -> void:
	if navigating:
		return

	navigating = true
	var error := get_tree().change_scene_to_file(REGISTER_PATH)

	if error != OK:
		navigating = false
		lbl_error.text = "Could not open Register. Check its scene path."


func _on_txt_username_text_submitted(_new_text: String) -> void:
	txt_password.grab_focus()


func _on_txt_password_text_submitted(_new_text: String) -> void:
	_on_btn_login_pressed()


# Keeps your existing development shortcut connected.
# It enters as the test user, not as a separate administrator.
func _on_admin_login_bypass_button_down() -> void:
	if navigating or not OS.is_debug_build():
		return

	if MockAuth.login("test", "123"):
		open_dashboard()
