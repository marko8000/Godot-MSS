extends Node


func node(from: Node, path: NodePath):
	return from.get_node(path)
	
	
func parent(from: Node):
	return from.get_parent()
	
	
func children(from: Node):
	return from.get_children()
