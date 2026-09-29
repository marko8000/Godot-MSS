extends RefCounted
class_name PlayerInputEvent


var actions_array : Array[MultiplayerAction]
var action_name_to_action_idx : Dictionary[String, int]
signal player_input(event : PlayerInputEvent)
func emit():
	player_input.emit(self)
	
	
func is_action(action : String) -> bool:
	return actions_array[action_name_to_action_idx[action]]._is_update
	

func get_float(action : String) -> float:
	var _action : ActionFloat = actions_array[action_name_to_action_idx[action]]
	return _action._value
	
	
func is_action_pressed(action : String) -> bool:
	var _action : ActionFloat = actions_array[action_name_to_action_idx[action]]
	return bool(_action._value)
	
	
func is_action_just_pressed(action : String) -> bool:
	var _action : ActionStrength = actions_array[action_name_to_action_idx[action]]
	if _action._is_update:
		return _action._value > _action._old_value and _action._value == 1
	else:
		return false
	
	
func is_action_released(action : String) -> bool:
	var _action : ActionStrength = actions_array[action_name_to_action_idx[action]]
	if _action._is_update:
		return _action._old_value > _action._value and _action._value == 0
	else:
		return false

func get_vector2(action : String) -> Vector2:
	var _action : ActionVector2 = actions_array[action_name_to_action_idx[action]]
	return _action._value
