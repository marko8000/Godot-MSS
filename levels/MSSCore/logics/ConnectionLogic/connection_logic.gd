extends MSSLogic
## ConnectionLogic is used to connect guests with host and share multiplayer peer with other logics
class_name ConnectionLogic


@onready var _EntityInterest := _MSSCore._EntityInterest

## host or guest
var peer_role : String

@export_category('Connection Settings')
@export var connection_mode : ConnectionMode :
	set(value):
		_peer_indices.clear()
		_free_slots.clear()
		connection_mode = value

var current_peer_idx : int
var _peer_indices : PackedInt32Array
var _free_slots : PackedInt32Array
var _peer_to_idx : Dictionary[int, int]

signal connection_peer_changed(new_peer : MultiplayerPeer)
signal peer_connected(peer_idx : int)
signal peer_disconnected(peer_idx : int)
	

static func get_from(from : Node) -> ConnectionLogic:
	return MSSCore.get_from(from)._ConnectionLogic


func _ready() -> void:
	if not multiplayer.peer_connected.is_connected(_peer_connected):
		multiplayer.peer_connected.connect(_peer_connected)
		multiplayer.peer_disconnected.connect(_peer_disconnected)
		multiplayer.connected_to_server.connect(_connected_to_server)
		multiplayer.connection_failed.connect(_connection_failed)
		multiplayer.server_disconnected.connect(_server_disconnected)
		
	
func _process(delta: float) -> void:
	Debug.dstate('peer_role', peer_role, self)
	
	
func host_create_server() -> void:
	peer_role = 'host'
	var peer := connection_mode.create_server()
	if peer:
		multiplayer.multiplayer_peer = peer
		connection_peer_changed.emit(multiplayer.multiplayer_peer)
		multiplayer.peer_connected.emit(1)
		_connected_to_server()
	
	
func guest_join_server() -> void:
	peer_role = 'guest'
	var peer := connection_mode.join_server()
	if peer:
		multiplayer.multiplayer_peer = peer
		connection_peer_changed.emit(multiplayer.multiplayer_peer)


func _peer_connected(peer_id : int):
	var peer_idx : int
	if not _free_slots.is_empty():
		peer_idx = _free_slots[-1]
		_free_slots.resize(_free_slots.size()-1)
		_peer_indices[peer_idx] = peer_id
	else:
		peer_idx = _peer_indices.size()
		_peer_indices.append(peer_id)
	_peer_to_idx[peer_id] = peer_idx
	peer_connected.emit(peer_id)
	Debug.dprint('Peer Connected ' + str(peer_id), peer_role)


func _peer_disconnected(peer_id : int):
	var peer_idx := _peer_indices[-1]
	_free_slots.append(peer_idx)
	_peer_to_idx.erase(peer_id)
	peer_disconnected.emit(peer_idx)
	Debug.dprint('Peer Disconnected ' + str(peer_id), peer_role)


func _connected_to_server():
	current_peer_idx = multiplayer.get_unique_id()
	Debug.dprint('Connected to Server', peer_role)


func _connection_failed():
	Debug.dprint('Connection Failed', peer_role)


func _server_disconnected():
	Debug.dprint('Server Disconnected', peer_role)
	
	
func is_player(node : Node) -> bool:
	if node.name.is_valid_int():
		var entity_idx := int(node.name)
		if _EntityInterest._player_data[current_peer_idx].player_entities.has(entity_idx):
			return true
	return false
	
	
func is_observer(node : Node) -> bool:
	if node.name.is_valid_int():
		var entity_idx := int(node.name)
		if _EntityInterest._observer_entities_by_peer_idx[current_peer_idx].has(entity_idx):
			return true
	return false
