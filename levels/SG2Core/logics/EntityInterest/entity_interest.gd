extends SG2Logic
class_name EntityInterest


@onready var _PlayerLifecycle := _SG2Core._PlayerLifeCycle

var _chunk_user_counts : Dictionary[Variant, int]

@export_category('Drawing Settings')
@export var drawing_distance : int = 1 # host's parameter is max for guest. drawing distance 1 is minimum
var _players : Dictionary[int, EntitiesPlayerData]
class EntitiesPlayerData:
	var uid : int
	var drawing_distance : int
	var player_id_nodes : Array[PlayerIdNode]
	func _init(_uid : int, _drawing_distance :  int) -> void:
		uid = _uid
		drawing_distance = _drawing_distance
	func _to_string() -> String:
		return '{uid: {uid}, drawing_distance: {dd}, player_id_nodes: {od}}'.format({'uid': uid, 'dd': drawing_distance, 'od': player_id_nodes})


func _ready() -> void:
	_PlayerLifecycle.player_state_changed.connect(_player_state_changed)
	
	
func _process(delta: float) -> void:
	await get_tree().process_frame
	_chunk_user_counts.clear()
	

func _player_state_changed(peer_id : int, state : PlayerLifecycle.PlayerState):
	match state:
		PlayerLifecycle.PlayerState.preparing:
			_players[peer_id] = EntitiesPlayerData.new(_PlayerLifecycle.players_data[peer_id].uid, drawing_distance)
		PlayerLifecycle.PlayerState.disconnected:
			_players.erase(peer_id)
	
