extends MSSLogic
## PathRegistry is used to share directories and files paths with other logics
class_name PathRegistry


var paths : Dictionary # every file has "_file"
					   # every directory has "_dir"


func paths_assignment():
	var _MSSExec = ExecManager.get_current_exec(self)
	var _ConnectionLogic := _MSSCore._ConnectionLogic
	
	paths.entities_dir = 'res://entities'

	paths.ServersData_dir = 'user://ServersData'
	paths.CurrentServerData_dir = File2ool.path([paths.ServersData_dir, _MSSCore.server_name])
	
	paths.entities_data_dir = File2ool.path([paths.CurrentServerData_dir, 'entities_data'])
	paths.entities_chunks_dir = File2ool.path([paths.entities_data_dir, 'chunks'])
	paths.entities_meta_file = File2ool.path([paths.entities_data_dir, 'entities_meta.json'])
	
	for _path in paths:
		if "_dir" in _path:
			DirAccess.make_dir_absolute(paths[_path])
	

func path(path_name):
	paths_assignment()
	
	if paths.has(path_name):
		return paths[path_name]
	else:
		return ''
