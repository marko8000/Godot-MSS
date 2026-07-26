extends AbstractExec


var is_exec

signal level_loaded

@warning_ignore("unused_private_class_variable")
@onready var _debug_control = %DebugPanel
@warning_ignore("unused_private_class_variable")
@onready var _command_line = %CommandLine
		

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_level('MainMenu')


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	manage_level_loading()


var loading_level_process_data = {'level_path': null, 'progress': [], 'status': 0}
func load_level(level_name):
	assert(FileAccess.file_exists(File2ool.path(['res://levels', level_name, level_name+'.tscn'])), 'Failed to load level '+'"'+level_name+'"')
	var _level_scene_path = File2ool.path(['res://levels/', level_name, level_name+'.tscn'])
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


func remove_current_level():
	if get_current_level(self) != null:
		get_current_level(self).queue_free()


func _input(event: InputEvent) -> void:
	if Input.is_action_pressed('Shift') and Input.is_action_just_pressed('Esc'):
		Debug.dprint('Quiting game', self.name)
		await get_tree().create_timer(0.5).timeout
		get_tree().quit()
	if Input.is_action_just_pressed("fullscreen"):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
