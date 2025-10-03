extends Node


var is_exec

signal level_loaded


func giveo(object_name):
	var control = $Control
	var debug_control = control.get_node('Debug')
	var commandline = control.get_node('CommandLine')
	
	if object_name == 'level':
		var children = get_children()
		for i in children:
			if 'is_level' in i:
				return i
		return null
	elif object_name == 'CommandLine':
		return commandline
	elif object_name == 'debug_control':
		return debug_control
		

var current_level_dir_path : String


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_level('mainmenu_alpha_dev')


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	manage_keybinds()
	manage_level_loading()


var loading_level_process_data = {'level_path': null, 'progress': [], 'status': 0}
func load_level(level_name):
	current_level_dir_path = FilesManager.create_path(['res://levels', level_name])
	assert(FileAccess.file_exists(FilesManager.create_path(['res://levels', level_name, 'level_info.txt'])), 'Failed to load level '+'"'+level_name+'"')
	var _level_scene_path = FilesManager.create_path(['res://levels/', level_name, FilesManager.give_value_from_file_readlines(FilesManager.create_path(['res://levels', level_name, 'level_info.txt']), 'level_main_scene')])
	loading_level_process_data['level_path'] = _level_scene_path
	loading_level_process_data['progress'] = []
	loading_level_process_data['status'] = 0
	ResourceLoader.load_threaded_request(_level_scene_path)
	return
	
	
func manage_level_loading():
	if loading_level_process_data['level_path'] != null:
		loading_level_process_data['status'] = ResourceLoader.load_threaded_get_status(loading_level_process_data['level_path'], loading_level_process_data['progress'])
		#print(str(loading_level_process_data['progress'][0]*100) + '%')
		if loading_level_process_data['status'] == ResourceLoader.THREAD_LOAD_LOADED:
			remove_current_level()
			#adding new level
			var _new_level = ResourceLoader.load_threaded_get(loading_level_process_data['level_path']).instantiate()
			await get_tree().process_frame
			add_child(_new_level)
			level_loaded.emit()
			
			Debug.dprint('Successfully loaded level: ' + loading_level_process_data['level_path'], self.name)
			loading_level_process_data['level_path'] = null
			loading_level_process_data['progress'] = []
			loading_level_process_data['status'] = 0
			
			
func give_current_level():
	var children = get_children()
	for i in children:
		if 'is_level' in i:
			return i
	return null


func remove_current_level():
	if give_current_level() != null:
		give_current_level().queue_free()


func manage_keybinds():
	if Input.is_action_just_pressed("debug"):
		var debug_control = giveo('debug_control')
		debug_control.visible = not debug_control.visible
	if Input.is_action_pressed('Shift') and Input.is_action_just_pressed('Esc'):
		Debug.dprint('Quiting game', self.name)
		pass
		get_tree().quit()
	
	if Input.is_action_just_pressed("command"):
		var commandline = giveo('CommandLine')
		if commandline.visible:
			commandline.get_node('VBoxContainer/LineEdit').clear()
			commandline.hide()
		else:
			commandline.show()
			commandline.get_node('VBoxContainer/LineEdit').grab_focus()
