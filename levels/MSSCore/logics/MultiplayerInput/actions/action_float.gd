@abstract
extends MultiplayerAction
class_name ActionFloat


var _value : float
var _old_value : float


func set_value(v : float):
	if v != _value:
		_is_update = true
	_old_value = _value
	_value = v
	
func add_value(v : float):
	set_value(_value+v)
	
	
func _write_buffer(input_buffer : StreamPeerBuffer, update_mask_pos : int):
	super(input_buffer, update_mask_pos)
	if _is_update:
		input_buffer.put_float(_value)
		
		
func _read_buffer(input_buffer : StreamPeerBuffer, update_mask_pos : int) -> void:
	super(input_buffer, update_mask_pos)
	if _is_update:
		var value := input_buffer.get_float()
		set_value(value)
