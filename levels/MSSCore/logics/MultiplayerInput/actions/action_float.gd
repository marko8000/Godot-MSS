@abstract
extends MultiplayerAction
class_name ActionFloat


var _value : float
var _old_value : float


func set_value(v : float):
	_is_update = true
	_is_zero = v == 0 and _value == 0
	_old_value = _value
	_value = v
	
func add_value(v : float):
	set_value(_value+v)
