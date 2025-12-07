extends CLIModule
class_name DefaultModule

var _SG2Exec : AbstractExec = ExecManager.get_current_exec(self)
var _current_level
var _commandline
var _debug_control


func start():
	_SG2Exec = ExecManager.get_current_exec(self)
	_current_level = _SG2Exec.get_current_level()
	_commandline = _SG2Exec._command_line
	_debug_control = _SG2Exec._debug_control


func quit():
	_SG2Exec.get_tree().quit()
	
	
func debug():
	var outp = 'Debug enabled' if _debug_control.visible else 'Debug disabled'
	_debug_control.visible = not _debug_control.visible
	_commandline.output(outp)


func sg2core(args : Array): # args = [peer_role, connection_mode, args]
	if args.size() == 2:
		_SG2Exec.load_level('SG2Core')
		await _SG2Exec.level_loaded
		_current_level = _SG2Exec.get_current_level()
		if args[0] == 'host':
			host(args.slice(1))
		elif args[0] == 'guest':
			guest([args.slice(1)])
	else:
		_commandline.output_error('To execute this command you have to specify peer_role, connection_mode, ...')
	
	
func host(args : Array): # args = [connection_mode, ...]
	if len(args) < 1:
		_commandline.output_error('To execute this command you have to specify connection_mode, ...')
		return
	if args[0] == 'enet': # args = [connection_mode, ipport]
		if len(args) == 1:
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
			_commandline.output('To execute this command you have to specify connection_mode, ip:port')


func guest(args : Array):
	if len(args) == 0:
		_commandline.output('[color=red]To execute this command you have to specify connection_mode, ...')
		return
	if args[0] == 'enet': # args = [connection_mode, ipport]
		if len(args) == 1:
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
				_commandline.output('[color=red]Failed to find _ConnectionLogic in current level[/color]')
		else:
			_commandline.output('[color=red]To execute this command you have to specify connection_mode, ip:port[/color]')
		
		
func clear_entities_storage():
	var entities_storage = _current_level.giveo('entities_storage')
	for child in entities_storage.get_children():
		child.queue_free()


func cee():
	clear_entities_storage()
	
