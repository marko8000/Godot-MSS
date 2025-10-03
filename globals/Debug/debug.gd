extends Node


signal doutput(print_text : String, printer_name : String)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	
	
func dprint(print_text : String, printer_name : String = self.name):
	doutput.emit(print_text, printer_name)
	print(printer_name + ': ' + print_text)
