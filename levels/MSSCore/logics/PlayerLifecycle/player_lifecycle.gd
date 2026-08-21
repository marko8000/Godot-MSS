extends MSSLogic
## MultiplayerLogic is used to manage players statuses
class_name PlayerLifecycle


@onready var _ConnectionLogic := _MSSCore._ConnectionLogic
@onready var _EntityFactory := _MSSCore._EntityFactory
@onready var _EntityInterest := _MSSCore._EntityInterest

var players_data : Array[PlayerData]
enum PlayerState {logging_in, logged_in, preparing, online, disconnected}
signal player_state_changed(peer_idx : int, player_state : PlayerState)
var _last_used_offline_id = 0


class PlayerData:
	var uid : int
	var personal_info := PersonalInfo.new()
	var state : PlayerState = PlayerState.logging_in
	func _to_string() -> String:
		return '{uid: {0}, state: {1}}'.format([uid, state])
	class PersonalInfo:
		var player_name : StringName
		var language : StringName


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await get_tree().process_frame
	_ConnectionLogic.connection_peer_changed.connect(_connection_peer_changed)
	player_state_changed.connect(_player_state_changed)
	_ConnectionLogic.peer_connected.connect(_peer_connected)
	_ConnectionLogic.peer_disconnected.connect(_peer_disconnected)
	

func _connection_peer_changed(new_peer):
	multiplayer.multiplayer_peer = new_peer
	Debug.dprint('Connection Peer Setted', self.name)


func _peer_connected(peer_idx : int):
	if _ConnectionLogic.peer_role == 'host':
		players_data.resize(max(peer_idx+1, players_data.size()))
		var player_data := PlayerData.new()
		player_data.personal_info.player_name = 'player' + str(peer_idx)
		player_data.uid = string_to_negative_id(player_data.personal_info.player_name)
		players_data[peer_idx] = player_data
		player_state_changed.emit(peer_idx, PlayerState.logging_in)
		
		
func _player_state_changed(peer_idx : int, state : PlayerState):
	players_data[peer_idx].state = state
	match state:
		PlayerState.logging_in:
			_last_used_offline_id -= 1
			players_data[peer_idx].uid = _last_used_offline_id
			player_state_changed.emit(peer_idx, PlayerState.logged_in)
		PlayerState.logged_in:
			player_state_changed.emit(peer_idx, PlayerState.preparing)
		PlayerState.preparing:
			var player_entity := await _EntityFactory.spawn_and_load('CharacterBody3D_FPS', {'position': Vector3(0, 5, 0)})
			_EntityInterest.register_player(int(player_entity.name), peer_idx)
			player_state_changed.emit(peer_idx, PlayerState.online)
		PlayerState.online:
			pass


func _peer_disconnected(peer_idx : int):
	if _ConnectionLogic.peer_role == 'host':
		player_state_changed.emit(peer_idx, PlayerState.disconnected)
		players_data[peer_idx] = null
		
		
func _connected_to_server():
	rpc_id(1, "set_language", ExecManager.language)
			

func uid_to_peer_idx(uid):
	for peer_idx in range(players_data.size()):
		if players_data[peer_idx].uid == uid:
			return peer_idx
			
			
@rpc("any_peer")
func set_language(language):
	var _peer_id = multiplayer.get_remote_sender_id()
	players_data[_peer_id].personal_info.language = language
	
	
func string_to_negative_id(player_name: String) -> int:
	var positive_hash = abs(hash(player_name))
	if positive_hash == 0:
		return -1
	return -positive_hash
