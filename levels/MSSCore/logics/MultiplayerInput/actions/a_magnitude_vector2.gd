extends ActionVector2
class_name ActionMagnitudeVector2


@export var negative_x := ActionMagnitude.new()
@export var positive_x := ActionMagnitude.new()
@export var negative_y := ActionMagnitude.new()
@export var positive_y := ActionMagnitude.new()


func _input(event : InputEvent):
	negative_x._input(event)
	positive_x._input(event)
	negative_y._input(event)
	positive_y._input(event)
	

func _reset_update() -> void:
	super()
	negative_x._reset_update()
	positive_x._reset_update()
	negative_y._reset_update()
	positive_y._reset_update()
	

func _not_update() -> void:
	negative_x._not_update()
	positive_x._not_update()
	negative_y._not_update()
	positive_y._not_update()
	
	
func _ready() -> void:
	negative_x._ready()
	positive_x._ready()
	negative_y._ready()
	positive_y._ready()
	
	
func _local_ready() -> void:
	negative_x._local_ready()
	positive_x._local_ready()
	negative_y._local_ready()
	positive_y._local_ready()


func _on_update():
	if negative_x._is_update or positive_x._is_update:
		set_value(Vector2(positive_x._value-negative_x._value, _value.y))
	if negative_y._is_update or positive_y._is_update:
		set_value(Vector2(_value.x, positive_y._value-negative_y._value))
	
	
func _write_buffer(input_buffer : StreamPeerBuffer, update_mask_pos : int):
	_on_update()
	super(input_buffer, update_mask_pos)
	if _is_update:
		input_buffer.put_float(_value.x)
		input_buffer.put_float(_value.y)
		

func _read_buffer(input_buffer : StreamPeerBuffer, update_mask_pos : int) -> void:
	super(input_buffer, update_mask_pos)
		
	if _is_update:
		var x := input_buffer.get_float()
		var y := input_buffer.get_float()
		set_value(Vector2(x, y))
