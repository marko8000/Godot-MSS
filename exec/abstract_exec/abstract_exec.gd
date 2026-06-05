@abstract
extends Node
class_name AbstractExec


func load_level(level_name):
	pass
	
	
func get_current_level(caller : Object):
	var children = get_children()
	for child in children:
		if child.scene_file_path.get_slice('/', 2) == 'levels':
			return child
	return null
