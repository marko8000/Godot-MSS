extends Node

@onready var SG2Exec = ExecManager.give_current_exec(self)
@onready var current_level = SG2Exec.giveo('level')
@onready var commandline = SG2Exec.giveo('CommandLine')
@onready var debug_control = SG2Exec.giveo('debug_control')

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	current_level = SG2Exec.giveo('level')
	commandline = SG2Exec.giveo("CommandLine")
	debug_control = SG2Exec.giveo('debug_control')


func quit():
	get_tree().quit()
	
	
func debug():
	var outp = 'Debug enabled' if debug_control.visible else 'Debug disabled'
	debug_control.visible = not debug_control.visible
	commandline.output(outp)


func sg2core(args : Array): # args = [peer_role, connection_mode, args]
	if args[1] == 'enet':
		if args.size() == 2:
			SG2Exec.load_level('SG2Core')
			await SG2Exec.level_loaded
			current_level = SG2Exec.giveo('level')
			if args[0] == 'host':
				host(args.slice(1))
			elif args[0] == 'guest':
				guest([args.slice(1)])
		else:
			commandline.output('[color=red]To execute this command you have to specify peer_role, connection_mode, ...')
	else:
		commandline.output('[color=red]Specified connection mode isn\'t supported[/color]')
	
func host(args : Array):
	if len(args) < 1:
		commandline.output('[color=red]To execute this command you have to specify connection_mode, ...')
		return
	if args[0] == 'enet': # args = [connection_mode, ipport]
		if len(args) == 1:
			if current_level.has_method('giveo'):
				var ConnectionLogic = current_level.giveo('ConnectionLogic')
				ConnectionLogic.peer_role = 'host'
				ConnectionLogic.connection_mode = ENetMultiplayerConnectionMode.new()
				if len(args) >= 2:
					ConnectionLogic.connection_mode.server_ip = args[1].split(':')[0]
					ConnectionLogic.connection_mode.server_port = args[1].split(':')[1]
					ConnectionLogic.host_create_server()
				elif len(args) == 1:
					ConnectionLogic.host_create_server()
			else:
				commandline.output('[color=red]Failed to find method "giveo" in current level[/color]')
		else:
			commandline.output('[color=red]To execute this command you have to specify connection_mode, ip:port[/color]')


func guest(args : Array):
	if len(args) == 0:
		commandline.output('[color=red]To execute this command you have to specify connection_mode, ...')
		return
	if args[0] == 'enet': # args = [connection_mode, ipport]
		if len(args) == 1:
			if current_level.has_method('giveo'):
				var ConnectionLogic = current_level.giveo('ConnectionLogic')
				ConnectionLogic.peer_role = 'guest'
				ConnectionLogic.connection_mode = ENetMultiplayerConnectionMode.new()
				if len(args) >= 2:
					ConnectionLogic.connection_mode.server_ip = args[1].split(':')[0]
					ConnectionLogic.connection_mode.server_port = args[1].split(':')[1]
					ConnectionLogic.guest_join_server()
				elif len(args) == 1:
					ConnectionLogic.guest_join_server()
			else:
				commandline.output('[color=red]Failed to find method "giveo" in current level[/color]')
		else:
			commandline.output('[color=red]To execute this command you have to specify connection_mode, ip:port[/color]')
		
		
func clear_entities_storage():
	var entities_storage = current_level.giveo('entities_storage')
	for child in entities_storage.get_children():
		child.queue_free()


func cee():
	clear_entities_storage()
	
