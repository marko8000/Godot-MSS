extends RefCounted
class_name PlayerInputEvent


var input_map : Array[MultiplayerAction]
var action_name_to_action_idx : Dictionary[String, int]
signal player_input(event : PlayerInputEvent)
func emit():
	player_input.emit(self)
	
	
func is_action(action : String) -> bool:
	return input_map[action_name_to_action_idx[action]]._is_update
	

func get_value(action : String) -> float:
	return input_map[action_name_to_action_idx[action]]._value
	
	
func is_action_pressed(action : String) -> bool:
	return bool(input_map[action_name_to_action_idx[action]]._value)
	
	
func is_action_just_pressed(action : String) -> bool:
	var _action := input_map[action_name_to_action_idx[action]]
	if _action._is_update:
		return _action._value > _action._old_value
	else:
		return false
	
	
func is_action_released(action : String) -> bool:
	var _action := input_map[action_name_to_action_idx[action]]
	if _action._is_update:
		return _action._old_value > _action._value
	else:
		return false

func get_vector(negative_x : String, positive_x : String, negative_y : String, positive_y : String) -> Vector2:
	return Vector2(
		get_value(positive_x)-
		get_value(negative_x),
		get_value(positive_y)-
		get_value(negative_y)
		)
