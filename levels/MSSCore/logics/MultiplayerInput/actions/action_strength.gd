@icon('res://levels/MSSCore/godot_icons/PackedFloat32Array.svg')
extends ActionMagnitude
class_name ActionStrength


func set_value(v : float):
	v = clampf(v, 0, 1)
	super(v)
