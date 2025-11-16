@icon('res://levels/SG2Core/x_res/x_images/sg_logo.svg')
extends Node
## DirectoriesPathsDistributor is used to share directories and files paths with other logics
class_name DirectoriesPathsDistributor


## parameter to separate data between few servers in one machine
@export var server_name : String = 'SG2CoreServer' # TODO: write redirect function with matched server_name

var paths : Dictionary


func paths_assignment():
	var _SG2Exec = ExecManager.give_current_exec(self)
	var _SG2Core : SG2Core = _SG2Exec.giveo('level')
	var _ConnectionLogic := _SG2Core._ConnectionLogic
	
	paths.general_entities_dir = 'res://entities'
	paths.level_dir = _SG2Exec.current_level_dir_path if scene_file_path.get_slice('/', 3) != 'SG2Core' else 'res://levels/SG2Core'
	paths.logics_dir = FilesManager.create_path([paths.level_dir, 'logics'])

	paths.ServersDataSaves = 'user://ServersDataSaves'
	paths.ThisServerDataSaves = FilesManager.create_path([paths.ServersDataSaves, server_name])
	
	paths.HostServerData = FilesManager.create_path([paths.ThisServerDataSaves, 'HostServerData'])
	paths.DownloadedContent = FilesManager.create_path([paths.ThisServerDataSaves, 'DownloadedContent'])
	paths.entities_data_file = FilesManager.create_path([paths.HostServerData, 'entities_data.json'])
	paths.users_auth_database_file = FilesManager.create_path([paths.HostServerData, 'users_auth.db'])
	paths.auth_token_file = FilesManager.create_path([paths.HostServerData, 'auth_token'])
	
	paths.PlayerInfo = 'user://PlayerInfo'
	paths.player_info_file = FilesManager.create_path([paths.PlayerInfo, 'player_info.txt'])
	
	
	paths_creating()
	

func paths_creating():
	for path in paths:
		if not '_file' in path:
			FilesManager.make_dir(paths[path])
	

func give_path(path_name):
	paths_assignment()
	
	return paths[path_name]
