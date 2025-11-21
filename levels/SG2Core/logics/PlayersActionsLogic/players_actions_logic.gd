@icon('res://levels/SG2Core/x_res/x_images/sg_logo.svg')
extends Node
## PlayersActionsLogic is used by host to get guests actions
## Examples of player actions: [Input], [InputEvent]
class_name PlayersActionsLogic


@onready var _SG2Core : SG2Core = ExecManager.give_current_exec(self).giveo('level')
@onready var _ConnectionLogic := _SG2Core._ConnectionLogic


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_ConnectionLogic.connection_peer_changed.connect(_connection_peer_changed)


var frame_num = 0
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	frame_num += 1
	var actions_list = [['move_right', 'button'], ['move_forward', 'button'], ['move_left', 'button'], ['move_back', 'button'], ["jump", 'button'], ['mouse_relative', 'mouse']]		
	if _ConnectionLogic.peer_role in ['guest', 'host']:
		var actions = get_actions_dict(actions_list)
		rpc_id(1, "host_get_player_actions_from_player", actions)

	
	if true:
		if mouse_relative_frame_num != frame_num:
			mouse_relative = Vector2.ZERO
			

func get_actions_dict(processing_actions : Array):
	var _actions : Dictionary
	for action in processing_actions:
		var action_name = action[0]
		var action_type = action[1]
		var action_arguments
		if len(action) >= 3:
			action_arguments = action[2]
		_actions[action_name] = []
		if action_type == 'button':
			if Input.is_action_pressed(action_name):
				_actions[action_name].append('pressed')
			if Input.is_action_just_pressed(action_name):
				_actions[action_name].append('just_pressed')
			if Input.is_action_just_released(action_name):
				_actions[action_name].append('just_released')
		elif action_type == 'mouse':
			if action_name == 'mouse_relative':
				_actions[action_name].append(mouse_relative)
		else:
			_actions[action_name].append(action_arguments)
	return _actions
		
		
@rpc("any_peer", 'call_local')
func host_get_player_actions_from_player(new_actions : Dictionary):
	var _player_id = multiplayer.get_remote_sender_id()
	get_node('peer'+str(_player_id)).actions = new_actions.duplicate(true)
	

func get_PlayerActions(player_type, id) -> PlayerActions:
	if player_type == 'peer':
		return get_node('peer'+str(id))
	return
	
	
func _connection_peer_changed(new_peer):
	multiplayer.multiplayer_peer = new_peer
	Debug.dprint('Connection Peer Setted', self.name)
	if _ConnectionLogic.peer_role == 'host':
		multiplayer.peer_connected.connect(_peer_connected)
		multiplayer.peer_disconnected.connect(_peer_disconnected)
		
		
func _peer_connected(id):
	var PlayerActions_instance = PlayerActions.new()
	PlayerActions_instance.name = 'peer'+str(id)
	add_child(PlayerActions_instance)
	print(get_node('peer'+str(id)).name)
	
	
func _peer_disconnected(id):
	if has_node('peer'+str(id)):
		get_node('peer'+str(id)).sleep = true
		

var mouse_relative = Vector2.ZERO
var mouse_relative_frame_num = 0
func _input(e):
	if e is InputEventMouseMotion:
		mouse_relative = e.relative
		mouse_relative_frame_num = frame_num
