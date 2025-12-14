@icon('res://levels/SG2Core/x_res/x_images/sg_logo.svg')
extends Node
## DirectoriesPathsDistributor is used to share directories and files paths with other logics
class_name DirectoriesPathsDistributor


var paths : Dictionary


func paths_assignment():
	var _SG2Exec = ExecManager.get_current_exec(self)
	var _SG2Core : SG2Core = _SG2Exec.get_current_level()
	var _ConnectionLogic := _SG2Core._ConnectionLogic
	
	paths.general_entities_dir = 'res://entities'
	paths.level_dir = _SG2Exec.current_level_dir_path if scene_file_path.get_slice('/', 3) != 'SG2Core' else 'res://levels/SG2Core'
	paths.logics_dir = FilesManager.create_path([paths.level_dir, 'logics'])

	paths.ServersData = 'user://ServersData'
	paths.CurrentServerData = FilesManager.create_path([paths.ServersData, _SG2Core.server_name])
	
	paths.entities_data_file = FilesManager.create_path([paths.CurrentServerData, 'entities_data.json'])
	paths.users_auth_database_file = FilesManager.create_path([paths.HostServerData, 'users_auth.db'])
	paths.auth_token_file = FilesManager.create_path([paths.HostServerData, 'auth_token'])
	
	paths.PlayerInfo = 'user://PlayerInfo'
	paths.player_info_file = FilesManager.create_path([paths.PlayerInfo, 'player_info.txt'])
	

func path(path_name):
	paths_assignment()
	
	return paths[path_name]
