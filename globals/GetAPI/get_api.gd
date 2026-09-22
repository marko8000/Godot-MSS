@tool
extends Node


func node(from: Node, path: NodePath):
	return from.get_node(path)
	
	
func parent(from: Node):
	return from.get_parent()
	
	
func children(from: Node):
	return from.get_children()


@warning_ignore("shadowed_variable")
func rename_unique(node: Node, parent: Node, new_name: StringName):
	var max_num = 0
	for child : Node in parent.get_children():
		if child.name.begins_with(new_name):
			var num_str = child.name.trim_prefix(new_name)
			if num_str.is_valid_int():
				max_num = max(max_num, num_str.to_int())
			elif num_str == "":
				max_num = max(max_num, 0)
	
	var new_num = max_num + 1
	@warning_ignore("incompatible_ternary")
	node.name = new_name + str(new_num) if new_num > 0 else new_name
