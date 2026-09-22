@icon('res://levels/MSSCore/godot_icons/float.svg')
extends ActionFloat
class_name ActionAxis


@export var negative_x : ActionMagnitude
@export var positive_x : ActionMagnitude


func _ready() -> void:
	_update_mask_size = 2
	
	
func _write_buffer(input_buffer : StreamPeerBuffer, update_mask_pos : int):
	set_value(positive_x._value-negative_x._value)
	negative_x._write_buffer(input_buffer, update_mask_pos)
	positive_x._write_buffer(input_buffer, update_mask_pos+1)
	
