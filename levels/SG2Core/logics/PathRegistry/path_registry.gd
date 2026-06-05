extends SG2Logic
## PathRegistry is used to share directories and files paths with other logics
class_name PathRegistry


var paths : Dictionary # every file has "_file"
					   # every directory has "_dir"


func paths_assignment():
	var _SG2Exec = ExecManager.get_current_exec(self)
	#var _SG2Core : SG2Core = _SG2Exec.get_current_level(self)
	var _ConnectionLogic := _SG2Core._ConnectionLogic
	
	paths.entities_dir = 'res://entities'

	paths.ServersData_dir = 'user://ServersData'
	paths.CurrentServerData_dir = File2ool.path([paths.ServersData_dir, _SG2Core.server_name])
	
	paths.entities_data_dir = File2ool.path([paths.CurrentServerData_dir, 'entities_data'])
	paths.entities_chunks_dir = File2ool.path([paths.entities_data_dir, 'chunks'])
	paths.entities_global_file = File2ool.path([paths.entities_data_dir, 'entities_global.json'])
	
	for _path in paths:
		if "_dir" in _path:
			DirAccess.make_dir_absolute(paths[_path])
	

func path(path_name):
	paths_assignment()
	
	if paths.has(path_name):
		return paths[path_name]
	else:
		return ''
