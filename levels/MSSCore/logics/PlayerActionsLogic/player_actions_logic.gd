extends MSSLogic
## PlayersActionsLogic is used by host to get guests actions
## Examples of player actions: [Input], [InputEvent]
class_name PlayerActionsLogic


@onready var _ConnectionLogic := _MSSCore._ConnectionLogic

var _player_input_events : Array[PlayerInputEvent]

enum {ACTION, MOUSE}


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await get_tree().process_frame
	_ConnectionLogic.connection_peer_changed.connect(_connection_peer_changed)
	_ConnectionLogic.peer_connected.connect(_peer_connected)
	_ConnectionLogic.peer_disconnected.connect(_peer_disconnected)


var frame_num = 0
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	frame_num += 1
	if _ConnectionLogic.peer_role in ['guest', 'host']:
		var actions = get_actions_dict()
		rpc_id(1, "host_get_player_actions_from_player", actions)

	
	if true:
		if mouse_relative_frame_num != frame_num:
			mouse_relative = Vector2.ZERO
			

func get_actions_dict() -> Dictionary[String, Array]:
	var processing_actions : Array[Array] = get_processing_actions()
	var _actions : Dictionary[String, Array]
	for action in processing_actions:
		var action_name = action[0]
		var action_type = action[1]
		_actions[action_name] = []
		if action_type == ACTION:
			if Input.is_action_pressed(action_name):
				_actions[action_name].append('pressed')
			if Input.is_action_just_pressed(action_name):
				_actions[action_name].append('just_pressed')
			if Input.is_action_just_released(action_name):
				_actions[action_name].append('just_released')
			if len(_actions[action_name]) == 0:
				_actions.erase(action_name)
		elif action_type == MOUSE:
			if action_name == 'mouse_relative':
				_actions[action_name].append(mouse_relative)
	return _actions
		
		
func get_processing_actions() -> Array[Array]:
	var processing_actions : Array[Array]
	for input_action in InputMap.get_actions():
		processing_actions.append([input_action, ACTION])
	processing_actions.append(['mouse_relative', MOUSE])
	return processing_actions
	
		
@rpc("any_peer", 'call_local')
func host_get_player_actions_from_player(new_actions : Dictionary[String, Array]):
	var _player_id = multiplayer.get_remote_sender_id()
	_player_input_events[_player_id]._update(new_actions.duplicate(true))
	

func get_PlayerInputEvent(peer_idx : int) -> PlayerInputEvent:
	if _player_input_events.size() >= peer_idx:
		return _player_input_events[peer_idx]
	return
	
	
func _connection_peer_changed(new_peer):
	multiplayer.multiplayer_peer = new_peer
	Debug.dprint('Connection Peer Setted', self.name)
		
		
func _peer_connected(peer_idx):
	_player_input_events.resize(max(peer_idx+1, _player_input_events.size()))
	_player_input_events[peer_idx] = PlayerInputEvent.new()
	
	
func _peer_disconnected(peer_idx):
	if _player_input_events.has(peer_idx):
		_player_input_events[peer_idx].sleep = true
		

var mouse_relative = Vector2.ZERO
var mouse_relative_frame_num = 0
func _input(e):
	if e is InputEventMouseMotion:
		mouse_relative = e.relative
		mouse_relative_frame_num = frame_num
