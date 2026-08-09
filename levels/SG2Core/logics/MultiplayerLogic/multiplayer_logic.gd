extends SG2Logic
## MultiplayerLogic is used to manage players statuses
class_name MultiplayerLogic


@onready var _ConnectionLogic := _SG2Core._ConnectionLogic
@onready var _AuthLogic : AuthLogic = _SG2Core._AuthLogic


var players_data : Dictionary[int, PlayerData]
enum player_status {logging_in, preparing, online}
var _last_used_offline_id = 0


class PlayerData:
	var uid : int
	var personal_info := PersonalInfo.new()
	var status : player_status = player_status.logging_in
	var status_is_blocked : bool = false
	func _to_string() -> String:
		return '{uid: {0}, status: {1}, status_is_blocked: {2}}'.format([uid, status, status_is_blocked])
	class PersonalInfo:
		var player_name : StringName
		var language : StringName


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_ConnectionLogic.connection_peer_changed.connect(_connection_peer_changed)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	

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
		var current_player_status = player_status.logging_in
		if current_player_status == player_status.logging_in:
			_last_used_offline_id -= 1
			players_data[peer_id].uid = _last_used_offline_id
		elif current_player_status == player_status.preparing:
			pass
		elif current_player_status == player_status.online:
			pass


func _peer_disconnected(peer_id):
	if _ConnectionLogic.peer_role == 'host':
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
