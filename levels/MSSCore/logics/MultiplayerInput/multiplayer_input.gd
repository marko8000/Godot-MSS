extends MSSLogic
class_name MultiplayerInput


@onready var _Exec := ExecManager.get_current_exec(self)
@onready var _ConnectionLogic := _MSSCore._ConnectionLogic

@export var input_map : Array[MultiplayerAction]
var _action_name_to_action_idx : Dictionary[String, int]

var _player_input : Array[PlayerInputEvent]


func connect_to(callable : Callable, peer_idx : int):
	_player_input[peer_idx].player_input.connect(callable)
	
	
func disconnect_from(callable : Callable, peer_idx : int):
	_player_input[peer_idx].player_input_signal.disconnect(callable)
		

func _ready() -> void:
	await get_tree().process_frame
	_ConnectionLogic.connection_peer_changed.connect(_connection_peer_changed)
	_ConnectionLogic.peer_connected.connect(_peer_connected)
	
	for action_idx in range(input_map.size()):
		var action := input_map[action_idx]
		_action_name_to_action_idx[action.action_name] = action_idx
		for event in action.events:
			event.action = action
	
	
func _connection_peer_changed(new_peer):
	multiplayer.multiplayer_peer = new_peer
	Debug.dprint('Connection peer setted.', self.name)
		
		
func _peer_connected(peer_idx):
	_player_input.resize(max(peer_idx+1, _player_input.size()))
	_player_input[peer_idx] = PlayerInputEvent.new()
	for action in input_map:
		_player_input[peer_idx].input_map.append(action.duplicate(true))
	_player_input[peer_idx].action_name_to_action_idx = _action_name_to_action_idx
		

func _process(delta: float) -> void:
	if _ConnectionLogic.current_peer_idx:
		var input_buffer := StreamPeerBuffer.new()
		for _i in range((input_map.size() + 7) / 8):
			input_buffer.put_u8(0)
		for action_idx in range(input_map.size()):
			var action := input_map[action_idx]
			var buffer_end := input_buffer.get_position()
			var byte_index := action_idx / 8
			var bit_index := action_idx % 8
			input_buffer.seek(byte_index)
			var mask_byte := input_buffer.get_u8()
			if action._is_update:
				mask_byte |= 1 << bit_index
			else:
				mask_byte &= ~(1 << bit_index)
			input_buffer.seek(byte_index)
			input_buffer.put_u8(mask_byte)
			input_buffer.seek(buffer_end)
			if action._is_update:
				input_buffer.put_float(action._value)
				action._is_update = false
			else:
				for event in action.events:
					event._is_not_update()
		rpc_id(MultiplayerPeer.TARGET_PEER_SERVER,
		'_host_get_player_input', input_buffer.data_array, _ConnectionLogic.current_peer_idx)
		input_buffer.clear()
	

func _input(event: InputEvent) -> void:
	if not _ConnectionLogic.current_peer_idx:
		return
	if not event.device in _Exec.input_devices:
		return
	for action_idx in range(input_map.size()):
		var action := input_map[action_idx]
		for d_input_event in action.events:
			d_input_event._input(event)
	
	
@rpc("any_peer", "call_local")
func _host_get_player_input(buffer : PackedByteArray, peer_idx : int):
	var peer_id := multiplayer.get_remote_sender_id()
	if _ConnectionLogic._peer_indices[peer_idx] != peer_id:
		peer_idx = _ConnectionLogic._peer_to_idx[multiplayer.get_remote_sender_id()]
	var input_buffer := StreamPeerBuffer.new()
	input_buffer.data_array = buffer
	input_buffer.seek((input_map.size()+7)/8)
	var input_event := _player_input[peer_idx]
	for action_idx in range(input_event.input_map.size()):
		var mask_byte := buffer[action_idx / 8]
		var bit_index := action_idx % 8
		var is_update := (mask_byte & (1 << bit_index)) != 0
		var action := input_event.input_map[action_idx]
		action._is_update = is_update
		if is_update:
			var value := input_buffer.get_float()
			action.set_value(value)
	input_event.player_input.emit(input_event)
			
