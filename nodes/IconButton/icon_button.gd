@tool
class_name IconButton
extends Button


@export var normal_icon : Texture2D
@export var pressed_icon : Texture2D


func _process(delta: float) -> void:
	if button_pressed:
		icon = pressed_icon
	else:
		icon = normal_icon
