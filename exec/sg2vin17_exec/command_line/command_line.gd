extends MarginContainer


@onready var SG2Exec = ExecManager.give_current_exec(self)
@onready var level = SG2Exec.giveo('level')
@onready var modules = $Modules
@onready var line_edit = $VBoxContainer/LineEdit
@onready var richtext_label = $VBoxContainer/RichTextLabel
@onready var command_line_dir = FilesManager.create_path([ExecManager.current_exec_dir_path, 'command_line'])
@onready var commands_modules_dir = FilesManager.create_path([command_line_dir, 'modules'])

var input_disabled : bool = false
var execute_input_disabled : bool = false


var commands_queue : Array


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	output('Command Line Log')
	add_modules()
	Debug.doutput.connect(_debug_output)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	level = SG2Exec.give_current_level()
	$VBoxContainer/RichTextLabel.get_v_scroll_bar().hide()
	for command_num in range(len(commands_queue)):
		command_translate(commands_queue[command_num])
		commands_queue.remove_at(command_num)


func _input(event: InputEvent) -> void:
	if not input_disabled:
		if not execute_input_disabled:
			if Input.is_action_just_pressed("enter"):
				var _command_text = line_edit.get_text()
				output('/' + _command_text)
				print('/' + _command_text)
				command(_command_text)
				line_edit.clear()
				hide()
	

# Adds command to queue
func command(command_text):
	commands_queue.append(command_text)


func command_translate(command_text):
	var _module_that_indicated_in_command_text = give_module_that_indicated_in_command(command_text)
	var _method_name = give_method_name_from_command(command_text)
	var _modules_which_have_method = give_modules_which_can_execute_method(_method_name)
	var _command_args = give_args_from_command(command_text)
	
	if _module_that_indicated_in_command_text == null: #if module not indicated
		if len(_modules_which_have_method) == 1:
			execute_command(_modules_which_have_method[0], _method_name, _command_args)
		elif len(_modules_which_have_method) > 1:
			output(['Few modules can execute your command:', 
			'[color=white]{modules_that_have_method}[/color]'.format({'modules_that_have_method' : _modules_which_have_method}),
			'Please indicate module number in command(0:command)'])
		elif len(_modules_which_have_method) == 0:
			output('[color=red]Failed to find modules which can execute your command[/color]')
	else:
		execute_command(_modules_which_have_method[_module_that_indicated_in_command_text], _method_name, _command_args)


func give_method_name_from_command(command_text: String):
	var _module_that_indicated_in_command_text = give_module_that_indicated_in_command(command_text)
	if _module_that_indicated_in_command_text == null:
		return command_text.split(' ')[0]
	else:
		return command_text.split(' ')[0].split(':')[1]


func give_module_that_indicated_in_command(command_text: String):
	var _indicated_module_num = null
	var _command_text_module_plus_method = command_text.split(' ')[0]
	if len(_command_text_module_plus_method.split(':')) > 1:
		_indicated_module_num = int(_command_text_module_plus_method.split(':')[0])
	return _indicated_module_num


func give_args_from_command(command_text: String):
	var _command_args : Array
	if len(command_text.split(' ')) > 1:
		_command_args = command_text.split(' ')
		_command_args.remove_at(0)
	return _command_args


func give_modules_which_can_execute_method(method_name):
	var _modules_list = give_modules_list()
	var _modules_which_have_method : Array
	for _checking_module in _modules_list:
		if _checking_module.has_method(method_name):
			_modules_which_have_method.append(_checking_module)
	return _modules_which_have_method


func give_modules_list():
	return modules.get_children()


func execute_command(module, method_name, args : Array):
	if module.get_method_argument_count(method_name) != 0:
		module.call(method_name, args)
	else:
		module.call(method_name)


func output(text, separating='\n', end='\n'):
	if typeof(text) == TYPE_STRING:
		richtext_label.set_text(richtext_label.text + '	— ' + text + end)
	elif typeof(text) == TYPE_ARRAY:
		for line in range(len(text)):
			if line == 0:
				richtext_label.set_text(richtext_label.text + '	— ' + text[line] + separating)
			else:
				if line != len(text):
					richtext_label.set_text(richtext_label.text + text[line] + separating)
				else:
					richtext_label.set_text(richtext_label.text + text[line] + end)
					
					
func _debug_output(print_text, printer_name):
	output(printer_name + ': ' + print_text)


func add_modules():
	var _available_modules : Array
	var _content_of_modules_directory = DirAccess.get_directories_at(commands_modules_dir)
	for module_dir_path in _content_of_modules_directory:
		var _module_main_scene_path = FilesManager.create_path([FilesManager.create_path([commands_modules_dir, module_dir_path]), FilesManager.give_value_from_file_readlines(FilesManager.create_path([commands_modules_dir, module_dir_path, 'cm_module_info.txt']), 'cm_module_main_scene')])
		var _module_file = load(_module_main_scene_path)
		var _module = _module_file.instantiate()
		modules.add_child(_module)
	
