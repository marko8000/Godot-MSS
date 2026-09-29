@abstract
extends Resource
class_name MultiplayerAction


var _update_mask_size : int = 1
var _is_update : bool

func _ready() -> void:
	pass
	
func _local_ready() -> void:
	pass

func _reset_update() -> void:
	_is_update = false
	
func _not_update() -> void:
	pass
	
func _write_buffer(input_buffer : StreamPeerBuffer, update_mask_pos : int):
	var buffer_end := input_buffer.get_position()
	var byte_index := update_mask_pos / 8
	var bit_index := update_mask_pos % 8
	input_buffer.seek(byte_index)
	var mask_byte := input_buffer.get_u8()
	if _is_update:
		mask_byte |= 1 << bit_index
	else:
		mask_byte &= ~(1 << bit_index)
	input_buffer.seek(byte_index)
	input_buffer.put_u8(mask_byte)
	input_buffer.seek(buffer_end)

func _read_buffer(input_buffer : StreamPeerBuffer, update_mask_pos : int) -> void:
	var mask_byte := input_buffer.data_array[update_mask_pos / 8]
	var bit_index := update_mask_pos % 8
	_is_update = (mask_byte & (1 << bit_index)) != 0
	
func _input(event : InputEvent):
	pass
