extends CLIModule
class_name StdModule

var _debug_control


func setup():
	_debug_control = _SG2Exec._debug_control


func level(args: Array):
	if len(args) == 0:
		_commandline.output_error("Level not entered")
	else:
		_SG2Exec.load_level(args[0])
	
	
func quit():
	_SG2Exec.get_tree().quit()
	
	
func debug():
	var outp = 'Debug enabled' if _debug_control.visible else 'Debug disabled'
	_debug_control.visible = not _debug_control.visible
	_commandline.output(outp)


func sg2core(args : Array):
	var main_help := 'To execute this command you have to specify peer_role, connection_mode, ...'
	if args.size() == 2:
		_SG2Exec.load_level('SG2Core')
		await _SG2Exec.level_loaded
		_current_level = _SG2Exec.get_current_level(self)
		if args[0] == 'host':
			host(args.slice(1))
		elif args[0] == 'guest':
			guest([args.slice(1)])
	else:
		_commandline.output_error(main_help)
	
	
func host(args : Array):
	var main_help := 'To execute this command you have to specify connection_mode, ...'
	if len(args) == 0:
		_commandline.output_error(main_help)
		return
		
	var mode_help : String
	if args[0] == 'enet':
		mode_help = 'To execute this command you have to specify connection_mode, ip:port'
		if len(args) == 2 and args[1] == 'help':
			_commandline.output(mode_help)
			return
		if '_ConnectionLogic' in _current_level:
			var _ConnectionLogic = _current_level._ConnectionLogic
			_ConnectionLogic.peer_role = 'host'
			_ConnectionLogic.connection_mode = ENetMultiplayerConnectionMode.new()
			if len(args) >= 2:
				_ConnectionLogic.connection_mode.server_ip = args[1].split(':')[0]
				_ConnectionLogic.connection_mode.server_port = args[1].split(':')[1]
				_ConnectionLogic.host_create_server()
			elif len(args) == 1:
				_ConnectionLogic.host_create_server()
		else:
			_commandline.output_error('Failed to find _ConnectionLogic in current level')
	else:
		_commandline.output(main_help)
		return

func guest(args : Array):
	var main_help := 'To execute this command you have to specify connection_mode, ...'
	if len(args) == 0:
		_commandline.output(main_help)
		return
		
	var mode_help : String
	if args[0] == 'enet':
		mode_help = 'To execute this command you have to specify connection_mode, ip:port'
		if len(args) == 2 and args[1] == 'help':
			_commandline.output(mode_help)
			return
		if '_ConnectionLogic' in _current_level:
			var _ConnectionLogic = _current_level._ConnectionLogic
			_ConnectionLogic.peer_role = 'guest'
			_ConnectionLogic.connection_mode = ENetMultiplayerConnectionMode.new()
			if len(args) >= 2:
				_ConnectionLogic.connection_mode.server_ip = args[1].split(':')[0]
				_ConnectionLogic.connection_mode.server_port = args[1].split(':')[1]
				_ConnectionLogic.guest_join_server()
			elif len(args) == 1:
				_ConnectionLogic.guest_join_server()
		else:
			_commandline.output('Failed to find _ConnectionLogic in current level')
	else:
		_commandline.output(main_help)
		return
		
		
func clear_entities_storage():
	var entities_storage = _current_level.giveo('entities_storage')
	for child in entities_storage.get_children():
		child.queue_free()


func cee():
	clear_entities_storage()
	
