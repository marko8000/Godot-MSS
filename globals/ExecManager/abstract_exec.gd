extends Node
class_name Exec


var input_devices : PackedInt32Array
var language : StringName = 'EN_us'


func load_level(level_name):
	pass
	
	
func get_current_level(caller : Object) -> Node:
	var children = get_children()
	for child : Node in children:
		if child.scene_file_path.get_slice('/', 2) == 'levels':
			return child
	return
