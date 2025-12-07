extends Panel


@onready var level_control_file = load('res://levels/mainmenu_alpha_dev/level_button.tscn')


func _on_back_pressed() -> void:
	$'../'.change_page('MainPage')
	
	
func _ready() -> void:
	refresh()
	
	
func refresh():
	for child in $ScrollContainer/VBoxContainer.get_children():
		child.queue_free()
	for level_name in DirAccess.get_directories_at('res://levels'):
		var level_control_instance = level_control_file.instantiate()
		level_control_instance.level_name = level_name
		level_control_instance.developer = str(FilesManager.give_value_from_file_readlines('res://levels/'+level_name+'/level_info.txt', 'developer'))
		$ScrollContainer/VBoxContainer.add_child(level_control_instance)
			
			
func load_level(level_name):
	ExecManager.get_current_exec(self).load_level(level_name)
