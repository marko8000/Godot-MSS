extends LineEdit
class_name LineEditLink


@export var redirect_mode : bool = true
@export var redirect_to : LineEdit


func _ready():
	gui_input.connect(_on_gui_input)


func _on_gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("LineEdit нажат мышью")
			if redirect_mode and redirect_to:
				await get_tree().process_frame
				redirect_to.grab_focus()
