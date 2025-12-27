@tool
extends Node


var language : String = 'EN_us'


func change_exec_to(exec_name : String, caller : Object):
	var exec_dir = File2ool.path(['res://exec', exec_name])
	var exec_scene_path = File2ool.path([exec_dir, exec_name + '.tscn'])
	get_tree().change_scene_to_file(exec_scene_path)
	Debug.dprint('Exec successfully changed to ' + exec_name, name)


func get_current_exec(caller : Object) -> AbstractExec:
	return get_tree().current_scene
	

func get_available_execs():
	var _available_execs = DirAccess.get_directories_at('res://exec')
	
	return _available_execs


func get_current_exec_name(caller : Object):
	return get_tree().current_scene.scene_file_path.get_slice('/', 3)
