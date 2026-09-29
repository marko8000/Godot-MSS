extends MSSLogic
class_name MultiplayerInput


@onready var _Exec := ExecManager.get_current_exec(self)
@onready var _ConnectionLogic := _MSSCore._ConnectionLogic

@export var input_map : Dictionary[String, MultiplayerAction]
var _actions_array : Array[MultiplayerAction]
var _action_name_to_action_idx : Dictionary[String, int]
var _full_update_mask_size : int

var _player_input : Array[PlayerInputEvent]


func connect_to(callable : Callable, peer_idx : int):
	_player_input[peer_idx].player_input.connect(callable)
	
	
func disconnect_from(callable : Callable, peer_idx : int):
	_player_input[peer_idx].player_input_signal.disconnect(callable)
		

func _ready() -> void:
	await get_tree().process_frame
	_ConnectionLogic.connection_peer_changed.connect(_connection_peer_changed)
	_ConnectionLogic.peer_connected.connect(_peer_connected)
	
	for action_name : String in input_map.keys():
		var action := input_map[action_name]
		action._ready()
		action._local_ready()
		_actions_array.append(action)
		_action_name_to_action_idx[action_name] = _actions_array.size()-1
		_full_update_mask_size += action._update_mask_size
	
	
func _connection_peer_changed(new_peer):
	multiplayer.multiplayer_peer = new_peer
	Debug.dprint('Connection peer setted.', self.name)
		
		
func _peer_connected(peer_idx : int):
	_player_input.resize(max(peer_idx+1, _player_input.size()))
	_player_input[peer_idx] = PlayerInputEvent.new()
	for action : MultiplayerAction in _actions_array:
		var new_action := action.duplicate()
		new_action._ready()
		_player_input[peer_idx].actions_array.append(new_action)
	_player_input[peer_idx].action_name_to_action_idx = _action_name_to_action_idx
		

func _process(delta: float) -> void:
	if _ConnectionLogic.current_peer_idx:
		var input_buffer := StreamPeerBuffer.new()
		for _i : int in range((_full_update_mask_size + 7) / 8):
			input_buffer.put_u8(0)
		var update_mask_pos : int = -1
		for action_idx : int in range(_actions_array.size()):
			var action := _actions_array[action_idx]
			update_mask_pos += 1
			action._write_buffer(input_buffer, update_mask_pos)
			update_mask_pos += action._update_mask_size-1
			if action._is_update:
				action._reset_update()
			else:
				action._not_update()
		rpc_id(MultiplayerPeer.TARGET_PEER_SERVER,
		'_host_get_player_input', input_buffer.data_array, _ConnectionLogic.current_peer_idx)
		input_buffer.clear()
	

func _input(event: InputEvent) -> void:
	if not _ConnectionLogic.current_peer_idx:
		return
	if not event.device in _Exec.input_devices:
		return
	for action_idx : int in range(input_map.size()):
		var action := _actions_array[action_idx]
		action._input(event)
	
@rpc("any_peer", "call_local")
func _host_get_player_input(buffer : PackedByteArray, peer_idx : int):
	var peer_id := multiplayer.get_remote_sender_id()
	if _ConnectionLogic._peer_indices[peer_idx] != peer_id:
		peer_idx = _ConnectionLogic._peer_to_idx[multiplayer.get_remote_sender_id()]
	var input_buffer := StreamPeerBuffer.new()
	input_buffer.data_array = buffer
	input_buffer.seek((_full_update_mask_size+7)/8)
	var input_event := _player_input[peer_idx]
	var update_mask_pos : int = -1
	for action_idx : int in range(input_event.actions_array.size()):
		var action := input_event.actions_array[action_idx]
		update_mask_pos += 1
		action._read_buffer(input_buffer, update_mask_pos)
		update_mask_pos += action._update_mask_size-1
	input_event.player_input.emit(input_event)
			
