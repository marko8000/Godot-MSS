@abstract
@icon('res://levels/MSSCore/godot_icons/Vector2.svg')
extends MultiplayerAction
class_name ActionVector2


var _value : Vector2
var _old_value : Vector2


func _ready() -> void:
	_update_mask_size = 1
	
	
func set_value(v : Vector2):
	if v != _value:
		_is_update = true
	_old_value = _value
	_value = v
