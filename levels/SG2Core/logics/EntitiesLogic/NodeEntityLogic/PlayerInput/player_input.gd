@tool
extends Node
class_name PlayerInput


func _get_configuration_warnings():
	var warnings = []
	var has_observer = false
	for child in get_parent().get_children():
		if child is Observer:
			has_observer = true
	if not has_observer:
		warnings.append('PlayerInput must be child of Node with Observer')
	return warnings
