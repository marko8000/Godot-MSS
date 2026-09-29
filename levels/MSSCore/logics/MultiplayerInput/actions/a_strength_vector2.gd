@icon('res://levels/MSSCore/godot_icons/PackedVector2Array.svg')
extends ActionMagnitudeVector2
class_name ActionStrengthVector2


func set_value(v : Vector2):
	v = v.normalized()
	super(v)
