@icon('res://levels/SG2Core/x_res/x_images/sg_logo.svg')
extends Node
## MultiplayerLogic is used to manage players statuses
class_name MultiplayerLogic


@onready var _SG2Core : SG2Core = ExecManager.give_current_exec(self).giveo('level')
@onready var _ConnectionLogic := _SG2Core._ConnectionLogic
@onready var _AuthLogic := _SG2Core._AuthLogic
@onready var _EntitiesLogic := _SG2Core._EntitiesLogic


var players_info : Dictionary[int, PlayerData]
enum player_status {logging_in, preparing, online}


class PlayerData:
	var reg_id
	var personal_info := PersonalInfo.new()
	var status : player_status = player_status.logging_in
	var status_is_blocked : bool = false
	func _to_string() -> String:
		return '{reg_id: {0}, status: {1}, status_is_blocked: {2}}'.format([reg_id, status, status_is_blocked])
	class PersonalInfo:
		var player_name : String
		var language : String


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_ConnectionLogic.connection_peer_changed.connect(_connection_peer_changed)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if _ConnectionLogic.peer_role == 'host':
		manage_players_statuses()
	

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
		players_info[peer_id] = PlayerData.new()
		players_info[peer_id].personal_info.player_name = 'player' + str(peer_id)


func _peer_disconnected(peer_id):
	if _ConnectionLogic.peer_role == 'host':
		players_info.erase(peer_id)
		
		
func _connected_to_server():
	rpc_id(1, "set_language", ExecManager.language)
		
		
func manage_players_statuses():
	for peer_id in players_info:
		var _current_player_status := players_info[peer_id].status
		if not players_info[peer_id].status_is_blocked:
			
			if _current_player_status == player_status.logging_in:
				block_player_status(peer_id)
				change_player_status(peer_id, player_status.preparing)
				
			elif _current_player_status == player_status.preparing:
				block_player_status(peer_id)
				change_player_status(peer_id, player_status.online)
				
			elif _current_player_status == player_status.online:
				block_player_status(peer_id)
		else:
			pass
				
				
func change_player_status(peer_id, new_status):
	players_info[peer_id].status = new_status
	players_info[peer_id].status_is_blocked = false
	
	
func block_player_status(peer_id):
	players_info[peer_id].status_is_blocked = true
	print(players_info)
			

func reg_id_to_peer_id(reg_id):
	for peer_id in players_info:
		if players_info[peer_id].reg_id == reg_id:
			return peer_id
			
			
@rpc("any_peer")
func set_language(language):
	var _peer_id = multiplayer.get_remote_sender_id()
	players_info[_peer_id].personal_info.language = language
