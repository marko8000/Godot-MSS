@abstract
extends Resource
class_name PlayerInputEvent


var actions : Dictionary[String, Array]
signal peer_input(event : PlayerInputEvent)


func _input(event : InputEvent, action : MultiplayerAction, input_buffer : StreamPeerBuffer):
	pass
	
	
func _update(new_actions : Dictionary[String, Array]) -> void:
	peer_input.emit(self)
	
	
func is_action_just_pressed(action : String):
	if action in actions:
		if 'just_pressed' in actions[action]:
			return true
	return false
	
	
func is_action_pressed(action: StringName):
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
