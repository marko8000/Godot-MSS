extends Control


@onready var _MSSExec := ExecManager.get_current_exec(self)
@onready var _current_level
@export var modules : Array[CLIModule] = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await get_tree().process_frame
	output('Command Line Log')
	Debug.on_doutput.connect(_debug_output)
	for module in modules:
		module._MSSExec = _MSSExec
		module._current_level = _MSSExec.get_current_level(self)
		module._commandline = self
		module.setup()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_current_level = _MSSExec.get_current_level(self)
	%RichTextLabel.get_v_scroll_bar().hide()
	if len(%LineEdit.text) > 0:
		if %LineEdit.text[0] == '/':
			%LineEdit.text = %LineEdit.text.substr(1)
	for module in modules:
		module._current_level = _current_level
		module._process(delta)
		

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("enter") and visible:
		var _command_text = %LineEdit.get_text()
		output('/' + _command_text)
		print('/' + _command_text)
		execute_command(_command_text)
		%LineEdit.clear()
	if Input.is_action_pressed('debug') and Input.is_action_just_pressed("command"):
		if visible:
			%LineEdit.clear()
			hide()
		else:
			UIManager.register(self)
			show()
			%LineEdit.grab_focus()
	
	if Input.is_action_just_pressed("Esc") and visible:
		hide()


func execute_command(command_text):
	var method_name = give_method_name_from_command(command_text)
	var command_args = give_args_from_command(command_text)
	var module : CLIModule
	
	for _module : CLIModule in modules:
		if _module.has_method(method_name):
			module = _module
			
	if module == null:
		output_error('Failed to find module with method "{0}"'.format([method_name]))
		return
	
	if module.get_method_argument_count(method_name) > 0:
		module.call(method_name, command_args)
	else:
		module.call(method_name)


func give_method_name_from_command(command_text: String) -> String:
	if len(command_text.split(' ')) > 0:
		return command_text.split(' ')[0]
	return ''


func give_args_from_command(command_text: String):
	var _command_args : Array
	if len(command_text.split(' ')) > 1:
		_command_args = command_text.split(' ').slice(1)
	return _command_args


func output(text : String):
	%RichTextLabel.append_text('\n- '+text)
	
	
func output_error(text : String):
	output('[color=red]'+text+'[/color]')
	UIManager.register(self)
	show()
	%LineEdit.grab_focus()
					
					
func _debug_output(print_text, printer_name):
	output(printer_name + ': ' + print_text)
	


func _on_control_focus_exited() -> void:
	print('focus')
