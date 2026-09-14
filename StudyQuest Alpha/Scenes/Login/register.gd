extends Panel

signal CreateUser(user, password)

func _on_register_button_down() -> void:
	CreateUser.emit($VBoxContainer/HBoxContainer/CreateUsername.text, $VBoxContainer/HBoxContainer2/CreatePassword.text)
	pass # Replace with function body.


func _on_btn_exit_button_down() -> void:
	queue_free()
	pass # Replace with function body.
