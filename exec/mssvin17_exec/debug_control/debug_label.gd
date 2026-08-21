extends VBoxContainer


var label_name : String


func _ready() -> void:
	%LabelName.text = str(label_name)+': '
	
	
func set_value(value):
	if false:
		pass
	elif false:
		pass
	else:
		%RichTextLabel.text = str(value)
