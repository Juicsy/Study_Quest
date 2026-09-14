extends Control

const APPDATA_PATH: String = "res://SaveData/sqAppData.save"

var logindata: Dictionary = {
	"Username": "",
	"Password": ""
}

func _ready() -> void:
	_load()

func _save() -> void:
	var file: FileAccess = FileAccess.open(APPDATA_PATH,FileAccess.WRITE)
	file.store_var(logindata)
	file.close()

func _load() -> void:
	if FileAccess.file_exists(APPDATA_PATH):
		var file: FileAccess = FileAccess.open(APPDATA_PATH,FileAccess.WRITE)
		var data: Dictionary = file.get_var()
		for i in data:
			if logindata.has(i):
				logindata[i] = data[i]
		file.close()
