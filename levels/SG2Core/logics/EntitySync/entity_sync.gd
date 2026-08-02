extends SG2Logic
class_name EntitySync


@onready var _ConnectionLogic := _SG2Core._ConnectionLogic

var _entities_can_start_working : bool = false
signal _entities_start_working
var _storage_set : Array[EntityStorageLogic]

@export_category('Drawing Settings')
@export var drawing_distance : int = 1 # host's parameter is max for guest. drawing distance 1 is minimum
var _players : Dictionary[int, EntitiesPlayerData]
class EntitiesPlayerData:
	var drawing_distance : int
	var observers : Array[Observer]
	func _init(_drawing_distance :  int) -> void:
		drawing_distance = _drawing_distance
	func _to_string() -> String:
		return '{drawing_distance: {dd}, observers: {od}}'.format({'dd': drawing_distance, 'od': observers})
var _chunks_users_num : Dictionary[Variant, int] ## if number of users is equal to or less than zero, chunk will be unloadedd

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_ConnectionLogic.connection_peer_changed.connect(_connection_peer_changed)


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
	#spawn_player('peer', peer_id)
	pass
	
	
func _peer_disconnected(peer_id):
	for observer : Observer in _players[peer_id].observers:
		if observer.current_chunk in _chunks_users_num:
			_chunks_users_num[observer.current_chunk] -= 1
	_players.erase(peer_id)
	
