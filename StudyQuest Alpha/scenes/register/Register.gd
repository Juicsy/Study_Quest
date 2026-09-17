extends Control

const LOGIN_PATH: String = "res://scenes/login/Login.tscn"

@onready var layout: VBoxContainer = $ScreenMargin/RegisterScroll/CenterLayout/RegisterPanel/RegisterMargin/RegisterLayout
@onready var txt_first_name: LineEdit = layout.get_node("NameRow/FirstNameSection/txtFirstName")
@onready var txt_last_name: LineEdit = layout.get_node("NameRow/LastNameSection/txtLastName")
@onready var txt_username: LineEdit = layout.get_node("UsernameSection/txtUsername")
@onready var txt_email: LineEdit = layout.get_node("EmailSection/txtEmail")
@onready var txt_password: LineEdit = layout.get_node("PasswordSection/txtPassword")
@onready var txt_confirm_password: LineEdit = layout.get_node("ConfirmPasswordSection/txtConfirmPassword")
@onready var show_password: CheckBox = layout.get_node("chkShowPassword")
@onready var lbl_error: Label = layout.get_node("lblError")
@onready var btn_register: Button = layout.get_node("btnRegister")
@onready var btn_back: Button = layout.get_node("LoginSection/btnBack")
@onready var success_dialog: AcceptDialog = $RegistrationSuccess
@onready var discard_dialog: ConfirmationDialog = $DiscardConfirmation

var fields: Array[LineEdit] = []
var registered: bool = false
var navigating: bool = false


func _ready() -> void:
	fields = [
		txt_first_name,
		txt_last_name,
		txt_username,
		txt_email,
		txt_password,
		txt_confirm_password
	]

	for field in fields:
		field.clear()

	lbl_error.text = ""
	show_password.set_pressed_no_signal(false)
	set_password_visibility(false)

	btn_register.pressed.connect(register_account)
	btn_back.pressed.connect(request_back)
	show_password.toggled.connect(set_password_visibility)

	for i in range(fields.size() - 1):
		fields[i].text_submitted.connect(_focus_next_field.bind(i + 1))

	txt_confirm_password.text_submitted.connect(submit_from_keyboard)

	success_dialog.dialog_text = "Account created. You can now log in."
	success_dialog.confirmed.connect(return_to_login)
	success_dialog.canceled.connect(return_to_login)

	discard_dialog.dialog_text = "Discard your registration details?"
	discard_dialog.confirmed.connect(return_to_login)

	txt_first_name.grab_focus()


func set_password_visibility(is_visible: bool) -> void:
	txt_password.secret = not is_visible
	txt_confirm_password.secret = not is_visible


func _focus_next_field(_text: String, index: int) -> void:
	fields[index].grab_focus()


func submit_from_keyboard(_text: String) -> void:
	register_account()


func register_account() -> void:
	if navigating or registered or discard_dialog.visible:
		return

	lbl_error.text = MockAuth.register_user(
		txt_first_name.text,
		txt_last_name.text,
		txt_username.text,
		txt_email.text,
		txt_password.text,
		txt_confirm_password.text
	)

	if not lbl_error.text.is_empty():
		return

	registered = true
	btn_register.disabled = true

	for field in fields:
		field.editable = false

	txt_password.clear()
	txt_confirm_password.clear()
	show_password.set_pressed_no_signal(false)
	set_password_visibility(false)
	show_password.disabled = true

	success_dialog.popup_centered()


func request_back() -> void:
	if navigating:
		return

	if registered:
		return_to_login()
		return

	for field in fields:
		if not field.text.is_empty():
			discard_dialog.popup_centered()
			return

	return_to_login()


func return_to_login() -> void:
	if navigating:
		return

	navigating = true
	var error := get_tree().change_scene_to_file(LOGIN_PATH)

	if error != OK:
		navigating = false
		lbl_error.text = "Could not open Login. Check LOGIN_PATH."
