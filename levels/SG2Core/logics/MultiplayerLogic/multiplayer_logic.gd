@icon('res://levels/SG2Core/x_res/x_images/sg_logo.svg')
extends Node


@onready var SG2Core = ExecManager.give_current_exec(self).giveo('level')
@onready var ConnectionLogic = SG2Core.giveo('ConnectionLogic')
@onready var AuthLogic = SG2Core.giveo('AuthLogic')
@onready var EntitiesLogic = SG2Core.giveo('EntitiesLogic')


var players_info : Dictionary # {peer_id: {reg_id : reg_id, user_id: user_id, player_name: player_name, status: player_status, status_is_blocked: false, language: language}}
# ALL PLAYER STATUSES:
# logging_in
# preparing
# online


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ConnectionLogic.connection_peer_changed.connect(_connection_peer_changed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if ConnectionLogic.peer_role == 'host':
		manage_players_statuses()
	

func _connection_peer_changed(new_peer):
	multiplayer.multiplayer_peer = new_peer
	Debug.dprint('Connection Peer Setted', self.name)
	if ConnectionLogic.peer_role == 'host':
		multiplayer.peer_connected.connect(_peer_connected)
		multiplayer.peer_disconnected.connect(_peer_disconnected)
	elif ConnectionLogic.peer_role == 'guest':
		multiplayer.connected_to_server.connect(_connected_to_server)


func _peer_connected(peer_id):
	if ConnectionLogic.peer_role == 'host':
		players_info[peer_id] = {'player_name': '', 'status': 'logging_in', 'status_is_blocked': false, 'language': 'us'}
		players_info[peer_id].player_name = 'player' + str(peer_id)


func _peer_disconnected(peer_id):
	if ConnectionLogic.peer_role == 'host':
		players_info.erase(peer_id)
		
		
func _connected_to_server():
	rpc_id(1, "set_language", ExecManager.language)
		
		
func manage_players_statuses():
	for peer_id in players_info:
		var _current_player_status = players_info[peer_id].status
		if not players_info[peer_id].status_is_blocked:
			
			if _current_player_status == 'logging_in':
				block_player_status(peer_id)
				change_player_status(peer_id, 'preparing')
				
			elif _current_player_status == 'preparing':
				block_player_status(peer_id)
				change_player_status(peer_id, 'online')
				
			elif _current_player_status == 'online':
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
	players_info[_peer_id].language = language
