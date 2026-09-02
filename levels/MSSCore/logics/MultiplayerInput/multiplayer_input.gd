extends MSSLogic
class_name MultiplayerInput

@onready var _ConnectionLogic := _MSSCore._ConnectionLogic

@export var input_map : Array[MultiplayerAction]

var _player_input_signals : Array[MultiplayerInputSignal]
class MultiplayerInputSignal:
	extends RefCounted
	signal player_input(event : PlayerInputEvent)


func connect_to(callable : Callable, peer_idx : int):
	_player_input_signals[peer_idx].player_input.connect(callable)
	
	
func disconnect_from(callable : Callable, peer_idx : int):
	_player_input_signals[peer_idx].player_input.disconnect(callable)
		

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await get_tree().process_frame
	_ConnectionLogic.connection_peer_changed.connect(_connection_peer_changed)
	_ConnectionLogic.peer_connected.connect(_peer_connected)
	_ConnectionLogic.peer_disconnected.connect(_peer_disconnected)
	
	
func _connection_peer_changed(new_peer):
	multiplayer.multiplayer_peer = new_peer
	Debug.dprint('Connection peer setted.', self.name)
		
		
func _peer_connected(peer_idx):
	_player_input_signals.resize(max(peer_idx+1, _player_input_signals.size()))
	_player_input_signals[peer_idx] = MultiplayerInputSignal.new()
	
	
func _peer_disconnected(peer_idx):
	pass


var _input_buffer := StreamPeerBuffer.new()
func _input(event: InputEvent) -> void:
	if not event.device in ExecManager.input_devices:
		return
	_input_buffer.resize((input_map.size() + 7) / 8)
	for action_num in range(input_map.size()):
		var action : MultiplayerAction = input_map[action_num]
		for p_input_event in action.events:
			p_input_event._input(event, action, _input_buffer)
		action.write_buffer(_input_buffer, action_num)
	rpc_id(MultiplayerPeer.TARGET_PEER_SERVER,
	'_host_get_player_input', _input_buffer.data_array)
	_input_buffer.clear()
	
	
@rpc("any_peer", "call_local")
func _host_get_player_input(buffer : PackedByteArray):
	for action_num in range(input_map.size()):
		
	
#var mouse_relative = Vector2.ZERO
#func _input(e):
	#if e is InputEventMouseMotion:
		#mouse_relative = e.relative
