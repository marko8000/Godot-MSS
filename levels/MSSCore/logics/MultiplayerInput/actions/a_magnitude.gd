extends ActionFloat
class_name ActionMagnitude


@export var events : Array[DeviceInputEvent]


func _ready() -> void:
	_update_mask_size = 1
	

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
	if _is_update:
		input_buffer.put_float(_value)
		
		
func _read_buffer(input_buffer : StreamPeerBuffer, update_mask_pos : int):
	var mask_byte := input_buffer.data_array[update_mask_pos / 8]
	var bit_index := update_mask_pos % 8
	_is_update = (mask_byte & (1 << bit_index)) != 0
	if _is_update:
		var value := input_buffer.get_float()
		set_value(value)
