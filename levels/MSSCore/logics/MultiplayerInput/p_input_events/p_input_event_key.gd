extends PlayerInputEvent
class_name PInputEventKey


@export var key : Key


func _input(event : InputEvent, action : MultiplayerAction, input_buffer : StreamPeerBuffer):
	if event is InputEventKey and event.keycode == key:
		if action is FloatAction:
			pass
		elif action is StrengthAction:
			action.value += 1
