extends VBoxContainer


@onready var SG2Core = ExecManager.give_current_exec().giveo('level')
@onready var AuthLogic = SG2Core.giveo('AuthLogic')
@onready var DirectoriesPathsDistributor = SG2Core.giveo('DirectoriesPathsDistributor')
@onready var ServersDataSaves_dir = DirectoriesPathsDistributor.give_path('ServersDataSaves')


var password : String


func refresh():
	password = ''
	

func _on_ok_pressed() -> void:
	password = $HBoxContainer/PasswordLineEdit.text
