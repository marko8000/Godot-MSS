@abstract
extends Resource
class_name MultiplayerAction


@export var action_name : String
@export var events : Array[DeviceInputEvent]

var _is_update : bool
var _old_value : float
var _value : float
func set_value(v : float):
	if v != _value:
		_is_update = true
	_old_value = _value
	_value = v
