extends DeviceInputEvent
class_name DeviceInputEventKey


@export var key : Key


func _input(event : InputEvent):
	if event is InputEventKey and event.keycode == key:
		if action is FloatAction:
			pass
		elif action is StrengthAction:
			if event.is_pressed():
				action.set_value(1)
			elif event.is_released():
				action.set_value(0)
