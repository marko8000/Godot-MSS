@icon('res://levels/MSSCore/godot_icons/float.svg')
extends ActionFloat
class_name ActionMagnitude


@export var events : Array[DeviceInputEvent]
	

func _local_ready() -> void:
	for event : DeviceInputEvent in events:
		event.action = self


func set_value(v : float):
	v = max(v, 0)
	super(v)
	
	
func _input(event : InputEvent):
	for device_input_event : DeviceInputEvent in events:
		device_input_event._input(event)


func _not_update() -> void:
	for event : DeviceInputEvent in events:
		event._not_update()
