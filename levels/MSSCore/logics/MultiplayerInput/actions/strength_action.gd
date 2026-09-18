@icon('res://levels/MSSCore/godot_icons/int.svg')
extends MultiplayerAction
class_name StrengthAction


func set_value(v : float):
	v = clampf(v, 0, 1)
	super(v)
		
