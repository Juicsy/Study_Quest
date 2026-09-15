extends Control

@onready var txt_username: LineEdit = $ScreenMargin/CenterLayout/LoginPanel/LoginMargin/LoginLayout/UsernameSection/txtUsername
@onready var txt_password: LineEdit = $ScreenMargin/CenterLayout/LoginPanel/LoginMargin/LoginLayout/PasswordSection/txtPassword
@onready var lbl_error: Label = $ScreenMargin/CenterLayout/LoginPanel/LoginMargin/LoginLayout/lblError

var username = "test"
var password = "123"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_chk_show_password_toggled(toggled_on: bool) -> void:
	txt_password.secret = not toggled_on

func _on_btn_login_pressed() -> void:
	if txt_username.text == username and txt_password.text == password:
		print("Login Successful!")
		get_tree().change_scene_to_file("res://scenes/dashboard/Dashboard.tscn")
	else:
		print("Login Failed")
		lbl_error.text = "Login Failed!"


func _on_txt_username_text_submitted(new_text: String) -> void:
	txt_password.grab_focus()

func _on_txt_password_text_submitted(new_text: String) -> void:
	_on_btn_login_pressed()
	
