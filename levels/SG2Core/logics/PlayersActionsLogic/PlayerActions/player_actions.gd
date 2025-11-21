extends Node
class_name PlayerActions


var actions : Dictionary
var sleep : bool = false
signal input
var old_actions : Dictionary


func _process(delta: float) -> void:
	if actions != old_actions:
		old_actions = actions
		input.emit()
	
	
func is_action_just_pressed(action : String):
	if action in actions:
		if 'just_pressed' in actions[action]:
			return true
	return false
	
	
func is_action_pressed(action : String):
	if action in actions:
		if 'pressed' in actions[action]:
			return true
	return false
	
	
func is_action_just_released(action : String):
	if action in actions:
		if 'just_released' in actions[action]:
			return true
	return false
	
	
func get_vector(negative_x: String, positive_x: String, negative_y: String, positive_y: String):
	var _vector : Vector2
	if is_action_pressed(negative_x):
		_vector.x -= 1
	if is_action_pressed(positive_x):
		_vector.x += 1
	if is_action_pressed(negative_y):
		_vector.y -= 1
	if is_action_pressed(positive_y):
		_vector.y += 1
	return _vector
