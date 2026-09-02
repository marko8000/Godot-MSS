extends MultiplayerAction
class_name StrengthAction


var value : float :
	set(v):
		value = clampf(v, 0, 1)
		

func _init(name : String, v : float) -> void:
	action_name = name
	value = v
	
	
func write_buffer(input_buffer : StreamPeerBuffer, action_num : int):
	var buffer_end := input_buffer.get_position()
	var byte_index := action_num / 8
	var bit_index := action_num % 8
	input_buffer.seek(byte_index)
	var mask_byte := input_buffer.get_u8()
	mask_byte |= 1 << bit_index
	input_buffer.seek(byte_index)
	input_buffer.put_u8(mask_byte)
	input_buffer.seek(buffer_end)
	input_buffer.put_float(value)
	value = 0
	
	
func read_buffer(input_buffer : StreamPeerBuffer, action_num : int, input_signal : MultiplayerInput.MultiplayerInputSignal):
	var value_position := input_buffer.get_position()
	
	var byte_index := action_num / 8
	var bit_index := action_num % 8
	
	input_buffer.seek(byte_index)
	var mask_byte := input_buffer.get_u8()
	
	if mask_byte & (1 << bit_index):
		input_buffer.seek(value_position)
		var v := input_buffer.get_float()
		input_signal.emit(StrengthAction.new(action_name, v))
