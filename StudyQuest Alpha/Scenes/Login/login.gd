extends Control

signal LoginUser(user, password)
signal CreateUser(user, password)

@export var Register: PackedScene

func _on_create_user_button_down() -> void:
	var register = Register.instantiate()
	add_child(register)
	register.CreateUser.connect(createUser)
	pass

func createUser(name, password):
	CreateUser.emit(name, password)
	pass
	
func _on_login_button_down() -> void:
	LoginUser.emit($VBoxContainer/HBoxContainer/Username.text ,$VBoxContainer/HBoxContainer2/Password.text)
	pass # Replace with function body.
