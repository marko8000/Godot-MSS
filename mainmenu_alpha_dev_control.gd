extends Control


@onready var Exec = ExecManager.give_current_exec()


func _on_button_pressed() -> void:
	Exec.load_level('mainmenu_alpha_dev')
