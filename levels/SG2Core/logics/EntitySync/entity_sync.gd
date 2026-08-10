extends SG2Logic
class_name EntitySync


@onready var _ConnectionLogic := _SG2Core._ConnectionLogic
@onready var _MultiplayerLogic := _SG2Core._MultiplayerLogic
@onready var _EntityFactory := _SG2Core._EntityFactory

var _entities_can_start_working : bool = false
signal _entities_start_working

var _requested_chunks : Array

var _chunks_buffer := ChunksBuffer.new()
class ChunksBuffer:
	var spawn_byte_data : Dictionary[Variant, PackedByteArray]
	var update_byte_data : Dictionary[Variant, PackedByteArray]
	
	func clear():
		spawn_byte_data.clear()
		update_byte_data.clear()
	

@export_category('Drawing Settings')
@export var drawing_distance : int = 1 # host's parameter is max for guest. drawing distance 1 is minimum
var _players : Dictionary[int, EntitiesPlayerData]
class EntitiesPlayerData:
	var uid : int
	var drawing_distance : int
	var observers : Array[Observer]
	func _init(_uid : int, _drawing_distance :  int) -> void:
		uid = uid
		drawing_distance = _drawing_distance
	func _to_string() -> String:
		return '{uid: {uid}, drawing_distance: {dd}, observers: {od}}'.format({'uid': uid, 'dd': drawing_distance, 'od': observers})


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_ConnectionLogic.connection_peer_changed.connect(_connection_peer_changed)


func _process(delta: float) -> void:
	await get_tree().process_frame
	_requested_chunks.clear()
	_chunks_buffer.clear()
	
	
func _connection_peer_changed(new_peer):
	_start()
	multiplayer.multiplayer_peer = new_peer
	Debug.dprint('Connection Peer Setted', self.name)
	if _ConnectionLogic.peer_role == 'host':
		multiplayer.peer_connected.connect(_peer_connected)
		multiplayer.peer_disconnected.connect(_peer_disconnected)
		

func _start():
	_entities_start_working.emit()
	_entities_can_start_working = true
	

func _peer_connected(peer_id):
	await get_tree().process_frame
	_players[peer_id] = EntitiesPlayerData.new(_MultiplayerLogic.players_data[peer_id].uid, 1)
	var player_entity := _EntityFactory.spawn('CharacterBody3D_FPS', {'position': Vector3(0, 10, 0)})
	_EntityFactory.spawn('Observer', 
	{'peer_id': peer_id, 'uid': _players[peer_id].uid},
	player_entity)
	
	
func _peer_disconnected(peer_id):
	#for observer : Observer in _players[peer_id].observers:
		#if observer.current_chunk in _chunks_users_num:
			#_chunks_users_num[observer.current_chunk] -= 1
	_players.erase(peer_id)
	
