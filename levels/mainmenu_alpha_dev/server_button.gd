extends HBoxContainer


var server_ip : String
var server_port : int
var icon : Texture2D
var server_name : String
var server_description : String
var developer : String
var players_count : int
var max_players : int


func _ready() -> void:
	$Icon.texture_normal = icon
	$Icon.texture_pressed = icon
	$VBoxContainer/NameLabel.text = server_name
	$VBoxContainer/Description.text = server_description
	$VBoxContainer2/DeveloperLabel.text = developer
	$VBoxContainer3/HBoxContainer/PlayersCount.text = str(players_count)
	$VBoxContainer3/MaxPlayers.text = str(max_players)
	$VBoxContainer4/NameLineEdit.text = server_name
	$VBoxContainer5/AddressLineEdit.text = server_ip + ':' + str(server_port)
	
	
func _on_icon_pressed() -> void:
	connect_to_server()


func _on_texture_button_pressed() -> void:
	connect_to_server()
	
	
func connect_to_server():
	ExecManager.give_current_exec(self).giveo('CommandLine').command('sg2core guest {ipport} {server_name}'.format({'ipport':server_ip+':'+str(server_port), 'server_name': server_name}))


func _on_settings_pressed() -> void:
	$VBoxContainer.visible = not $VBoxContainer.visible
	$VBoxContainer2.visible = not $VBoxContainer2.visible
	$VBoxContainer3.visible = not $VBoxContainer3.visible
	$VBoxContainer4.visible = not $VBoxContainer4.visible
	$Control.visible = not $Control.visible
	$VBoxContainer5.visible = not $VBoxContainer5.visible
	$Apply.visible = not $Apply.visible
	$VBoxContainer6.visible = not $VBoxContainer6.visible


func _on_apply_pressed() -> void:
	DirAccess.rename_absolute('user://ServersDataSaves/'+server_name, 'user://ServersDataSaves/'+$VBoxContainer4/NameLineEdit.text)
	var address_splitted = $VBoxContainer5/AddressLineEdit.text.split(':')
	if len(address_splitted) < 2:
		FilesManager.change_value_from_file_readlines('user://ServersDataSaves/'+server_name+'/connection_settings.txt', 'ip', $VBoxContainer5/AddressLineEdit.text)
	else:
		FilesManager.change_value_from_file_readlines('user://ServersDataSaves/'+server_name+'/connection_settings.txt', 'ip', address_splitted[0])
		FilesManager.change_value_from_file_readlines('user://ServersDataSaves/'+server_name+'/connection_settings.txt', 'port', address_splitted[1])
		
		
	$'../../../../'.refresh()


func _on_remove_pressed() -> void:
	DirAccess.remove_absolute('user://ServersDataSaves/'+server_name)
	$'../../../../'.refresh()
