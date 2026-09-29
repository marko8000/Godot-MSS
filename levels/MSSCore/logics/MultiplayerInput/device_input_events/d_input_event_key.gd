@icon('res://levels/MSSCore/godot_icons/InputEventKey.svg')
extends DeviceInputEvent
class_name DeviceInputEventKey


@export var key : Key
@export var sensitivity : float = 100 :
	set(v):
		sensitivity = max(v, 0)


func _input(event : InputEvent):
	var is_released := false
	var is_pressed := Input.is_key_pressed(key)
	if event is InputEventKey and event.keycode == key and event.is_released():
		is_released = true
	if is_pressed:
		_is_active = true
	elif is_released:
		_is_active = false
	
	if action is ActionMagnitude:
		if is_pressed:
			action.set_value(sensitivity)
		elif is_released:
			action.set_value(0)
