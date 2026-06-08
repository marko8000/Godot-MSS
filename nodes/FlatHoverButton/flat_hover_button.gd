@tool
class_name FlatHoverButton
extends Button


func _ready() -> void:
	flat = true
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	flat = false
	

func _on_mouse_exited() -> void:
	flat = true
