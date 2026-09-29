@icon('res://levels/MSSCore/godot_icons/InputEventMouseMotion.svg')
extends DeviceInputEvent
class_name DeviceInputEventMouseMotion


@export var axis := Axis.negative_x
enum Axis {negative_x, positive_x, negative_y, positive_y}
@export var sensitivity : float = 1.0


func _input(event : InputEvent):
	if event is InputEventMouseMotion:
		_is_active = true
		var value : float
		match axis:
			Axis.negative_x:
				value = -min(0, event.relative.x)
			Axis.positive_x:
				value = max(0, event.relative.x)
			Axis.negative_y:
				value = -min(0, event.relative.y)
			Axis.positive_y:
				value = max(0, event.relative.y)
		value *= sensitivity
		if action is ActionStrength:
			pass
		elif action is ActionMagnitude:
			action.set_value(value)
			
			
func _not_update():
	if _is_active:
		_is_active = false
		action.set_value(0)
