extends Node


signal on_doutput(print_text : String, printer_name : String)
signal on_dstate(state : String, value)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	
	
func dprint(print_text : String, printer_name : String = self.name):
	on_doutput.emit(print_text, printer_name)
	print(printer_name + ': ' + print_text)
	
	
func dstate(state : String, value):
	on_dstate.emit(state, value)
