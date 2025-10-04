extends Panel


@onready var server_button_file = load('res://levels/mainmenu_alpha_dev/server_button.tscn')


func _on_back_pressed() -> void:
	$'../'.change_page('MainPage')
	
	
func _ready() -> void:
	refresh()
	
	
func refresh():
	DirAccess.make_dir_absolute('user://ServersDataSaves')
	for child in $VBoxContainer/ScrollContainer/VBoxContainer.get_children():
		child.queue_free()
	for server_name in DirAccess.get_directories_at('user://ServersDataSaves'):
		var server_button_instance = server_button_file.instantiate()
		server_button_instance.server_ip = str(FilesManager.give_value_from_file_readlines('user://ServersDataSaves/'+server_name+'/'+'connection_settings.txt', 'ip')) if FilesManager.give_value_from_file_readlines('user://ServersDataSaves/'+server_name+'/'+'connection_settings.txt', 'ip') != null else 'localhost'
		server_button_instance.server_port = int(FilesManager.give_value_from_file_readlines('user://ServersDataSaves/'+server_name+'/'+'connection_settings.txt', 'port')) if FilesManager.give_value_from_file_readlines('user://ServersDataSaves/'+server_name+'/'+'connection_settings.txt', 'port') != null else 17172
		server_button_instance.server_name = server_name
		server_button_instance.server_description = FileAccess.open('user://ServersDataSaves/'+server_name+'/'+'description.txt', FileAccess.READ).get_as_text() if FileAccess.open('user://ServersDataSaves/'+server_name+'/'+'description.txt', FileAccess.READ) != null else ''
		server_button_instance.developer = str(FilesManager.give_value_from_file_readlines('user://ServersDataSaves/'+server_name+'/'+'guest_server_info.txt', 'developer'))
		server_button_instance.players_count = int(FilesManager.give_value_from_file_readlines('user://ServersDataSaves/'+server_name+'/'+'guest_server_info.txt', 'players_count')) if FilesManager.give_value_from_file_readlines('user://ServersDataSaves/'+server_name+'/'+'guest_server_info.txt', 'players_count') != null else 0
		server_button_instance.max_players = int(FilesManager.give_value_from_file_readlines('user://ServersDataSaves/'+server_name+'/'+'guest_server_info.txt', 'max_players')) if FilesManager.give_value_from_file_readlines('user://ServersDataSaves/'+server_name+'/'+'guest_server_info.txt', 'max_players') != null else 0
		$VBoxContainer/ScrollContainer/VBoxContainer.add_child(server_button_instance)


func _on_add_pressed() -> void:
	$HBoxContainer.visible = not $HBoxContainer.visible
	if not $HBoxContainer.visible:
		var new_server_name : String = $HBoxContainer/NewNameLineEdit.text
		if new_server_name.replace(' ', '') == '':
			new_server_name = 'Server'
		var i = 1
		while true:
			i += 1
			if DirAccess.dir_exists_absolute('user://ServersDataSaves/'+new_server_name):
				new_server_name = $HBoxContainer/NewNameLineEdit.text + ' ' + str(i)
			else:
				break
		DirAccess.make_dir_absolute('user://ServersDataSaves/'+new_server_name)
		var address_splitted = $HBoxContainer/NewAddressLineEdit.text.split(':')
		if len(address_splitted) < 2:
			FilesManager.change_value_from_file_readlines('user://ServersDataSaves/'+new_server_name+'/connection_settings.txt', 'ip', $HBoxContainer/NewAddressLineEdit.text)
		else:
			FilesManager.change_value_from_file_readlines('user://ServersDataSaves/'+new_server_name+'/connection_settings.txt', 'ip', address_splitted[0])
			FilesManager.change_value_from_file_readlines('user://ServersDataSaves/'+new_server_name+'/connection_settings.txt', 'port', address_splitted[1])
		$HBoxContainer/NewNameLineEdit.clear()
		$HBoxContainer/NewAddressLineEdit.clear()
		refresh()



func _on_new_name_line_edit_text_submitted(new_text: String) -> void:
	$HBoxContainer/NewAddressLineEdit.grab_focus()


func _on_new_address_line_edit_text_submitted(new_text: String) -> void:
	_on_add_pressed()
