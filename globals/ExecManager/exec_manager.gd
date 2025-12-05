@tool
extends Node


@onready var avaible_execs : Array = give_available_execs()
var old_exec_name = null
var current_exec_name : String
var current_exec_file_path : String
var current_exec_dir_path : String

var language : String = 'EN_us'


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not Engine.is_editor_hint():
		execs_changing()


func change_exec_to(exec_name, caller : Object):
	var exec_dir = FilesManager.create_path(['res://exec', exec_name])
	var exec_scene_path = FilesManager.create_path([exec_dir, FilesManager.give_value_from_file_readlines(FilesManager.create_path([exec_dir, 'exec_info.txt']), 'exec_main_scene')])
	get_tree().change_scene_to_file(exec_scene_path)
	current_exec_file_path = exec_scene_path
	current_exec_dir_path = exec_dir
	return Debug.dprint('Exec successfully changed to ' + exec_name, name)


func give_current_exec(caller : Object):
	var root_children = get_tree().root.get_children()
	for child in root_children:
		if 'is_exec' in child:
			return child
	return null
	

func give_available_execs():
	var _available_execs : Array
	var _content_of_exec_dir = DirAccess.get_directories_at('res://exec')
	
	return _available_execs


func give_current_exec_name(caller : Object):
	return get_tree().current_scene.name


func execs_changing():
	avaible_execs = give_available_execs()
	current_exec_name = give_current_exec_name(self)
	if old_exec_name != null:
		if old_exec_name != current_exec_name:
			var copy_of_old_name = old_exec_name
			old_exec_name = current_exec_name
			return Debug.dprint('Current exec changed from ' + copy_of_old_name + ' to ' + current_exec_name, name)
	old_exec_name = current_exec_name
