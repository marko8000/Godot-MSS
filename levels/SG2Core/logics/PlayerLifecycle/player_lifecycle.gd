extends SG2Logic
## MultiplayerLogic is used to manage players statuses
class_name PlayerLifecycle


@onready var _ConnectionLogic := _SG2Core._ConnectionLogic
@onready var _AuthLogic := _SG2Core._AuthLogic
@onready var _EntityFactory := _SG2Core._EntityFactory


var players_data : Dictionary[int, PlayerData]
enum PlayerState {logging_in, logged_in, preparing, online, disconnected}
signal player_state_changed(peer_id : int, player_state : PlayerState)
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
	

func _connection_peer_changed(new_peer):
	multiplayer.multiplayer_peer = new_peer
	Debug.dprint('Connection Peer Setted', self.name)
	if _ConnectionLogic.peer_role == 'host':
		multiplayer.peer_connected.connect(_peer_connected)
		multiplayer.peer_disconnected.connect(_peer_disconnected)
	elif _ConnectionLogic.peer_role == 'guest':
		multiplayer.connected_to_server.connect(_connected_to_server)


func _peer_connected(peer_id):
	if _ConnectionLogic.peer_role == 'host':
		players_data[peer_id] = PlayerData.new()
		players_data[peer_id].personal_info.player_name = 'player' + str(peer_id)
		players_data[peer_id].uid = string_to_negative_id(players_data[peer_id].personal_info.player_name)
		player_state_changed.emit(peer_id, PlayerState.logging_in)
		
		
func _player_state_changed(peer_id : int, state : PlayerState):
	players_data[peer_id].state = state
	match state:
		PlayerState.logging_in:
			_last_used_offline_id -= 1
			players_data[peer_id].uid = _last_used_offline_id
			player_state_changed.emit(peer_id, PlayerState.logged_in)
		PlayerState.logged_in:
			player_state_changed.emit(peer_id, PlayerState.preparing)
		PlayerState.preparing:
			var player_entity := await _EntityFactory.spawn_and_load('CharacterBody3D_FPS', {'position': Vector3(0, 5, 0)})
			_EntityFactory.spawn('PlayerIdNode', 
			{'peer_id': peer_id, 'uid': players_data[peer_id].uid}, 
			player_entity)
			player_state_changed.emit(peer_id, PlayerState.online)
		PlayerState.online:
			pass


func _peer_disconnected(peer_id):
	if _ConnectionLogic.peer_role == 'host':
		player_state_changed.emit(peer_id, PlayerState.disconnected)
		players_data.erase(peer_id)
		
		
func _connected_to_server():
	rpc_id(1, "set_language", ExecManager.language)
			

func uid_to_peer_id(uid):
	for peer_id in players_data:
		if players_data[peer_id].uid == uid:
			return peer_id
			
			
@rpc("any_peer")
func set_language(language):
	var _peer_id = multiplayer.get_remote_sender_id()
	players_data[_peer_id].personal_info.language = language
	
	
func string_to_negative_id(player_name: String) -> int:
	var positive_hash = abs(hash(player_name))
	if positive_hash == 0:
		return -1
	return -positive_hash
