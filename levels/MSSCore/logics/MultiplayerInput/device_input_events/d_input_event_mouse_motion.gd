extends DeviceInputEvent
class_name DeviceInputEventMouseMotion


@export var axis := Axis.x
enum Axis {x, y}


func _input(event : InputEvent):
	if event is InputEventMouseMotion:
		if action is FloatAction:
			action.set_value(event.relative[axis])
		elif action is StrengthAction:
			pass
			
			
func _is_not_update():
	action.set_value(0)
