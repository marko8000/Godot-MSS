@tool
extends Node


func giveo(object_name):
	if object_name == 'ZipArchiver':
		return $ZipArchiver


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


func path(components : Array, to_make_dir : bool = false) -> String:
	var _path : String
	for component in components:
		_path += component + '/'
	_path = fix_dir_path(_path)
	if to_make_dir:
		make_dir(_path)
	return _path
	
	
func make_dir(dir):
	var _dir_splitted_to_base_and_dir = fix_dir_path(dir).split('://')
	var _base = _dir_splitted_to_base_and_dir[0] + '://'
	var _dir = _dir_splitted_to_base_and_dir[1]
	var _current_dir = _base
	for folder in _dir.split('/'):
		_current_dir = File2ool.create_path([_current_dir, folder])
		DirAccess.make_dir_absolute(_current_dir)


func fix_dir_path(dir_path: String, slash_in_the_end: bool = false):
	var fixed_dir_path = ''
	for i in range(len(dir_path)):
		if dir_path[i] == '/':
			if i+1 != len(dir_path) and i != 0:
				if (dir_path[i-1] == ':' and dir_path[i+1] == '/') or dir_path[i+1] != '/':
					fixed_dir_path += dir_path[i]
				elif dir_path[i+1] == '/':
					continue
		else:
			fixed_dir_path += dir_path[i]
	if slash_in_the_end:
		fixed_dir_path += '/'
	return fixed_dir_path


func give_value_from_file_readlines(file_path:String, key:String):
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null: return null
	var file_readlines = file.get_as_text().split('\n')
	for readline in file_readlines:
		var readline_splited = readline.split(':')
		if len(readline_splited) <= 1: continue
		if readline_splited[0] == key:
			readline_splited[1] = readline_splited[1].strip_edges()
			if readline_splited[1] == 'true':
				return true
			elif readline_splited[1] == 'false':
				return false
			elif readline_splited[1] == '':
				return null
			elif readline_splited[1] == 'null':
				return null
			elif readline_splited[1].is_valid_int():
				return int(readline_splited[1])
			elif readline_splited[1].is_valid_float():
				return float(readline_splited[1])
			else:
				var result : String
				for part_num in range(1, len(readline_splited)):
					result += readline_splited[part_num]
					if part_num != len(readline_splited)-1:
						result += ':'
				return result
	return null
	
	
func change_value_from_file_readlines(file_path:String, key:String, new_value):
	var file = FileAccess.open(file_path, FileAccess.READ_WRITE)
	if file == null: return
	var text = file.get_as_text()
	var file_readlines = text.split('\n')
	for line_num in len(file_readlines)+1:
		var readline_splited = file_readlines[line_num].split(':')
		if readline_splited[0] == key:
			file_readlines[line_num] = readline_splited[0] + ':' + str(new_value)
			break
		if line_num == len(file_readlines):
			file_readlines.append(key+':'+str(new_value))
	var new_text : String
	for readline in file_readlines:
		new_text += readline + '\n'
	file.store_string(new_text)
	file.close()
	
	
func refresh_file_system() -> void:
	var file_system = EditorInterface.get_resource_filesystem()
	file_system.scan()
	
	
func file_system_dock_navigate_to(_path: String) -> void:
	var fs_dock = EditorInterface.get_file_system_dock()
	fs_dock.navigate_to_path(_path)
