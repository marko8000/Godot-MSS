@icon('res://levels/SG2Core/x_res/x_images/sg_logo.svg')
extends Node
## ConnectionLogic is used to connect guests with host and share multiplayer peer with other logics
class_name ConnectionLogic


var peer = ENetMultiplayerPeer.new()
## host or guest
var peer_role : String

@export_category('Connection Settings')
@export var connection_mode : AbstractConnectionMode = null


signal connection_peer_changed(new_peer)
var my_peer_id
	
	
func _process(delta: float) -> void:
	Debug.dstate('peer_role', peer_role, self)
	
	
func host_create_server():
	peer_role = 'host'
	if connection_mode is ENetMultiplayerConnectionMode:
		if connection_mode.server_ip != null and connection_mode.server_port != null:
			multiplayer.peer_connected.connect(_peer_connected)
			multiplayer.peer_disconnected.connect(_peer_disconnected)
			multiplayer.connected_to_server.connect(_connected_to_server)
			peer.create_server(connection_mode.server_port) #port = open LISTENING port from cmd command:netstat -aon
			peer.set_bind_ip(connection_mode.server_ip)
			multiplayer.multiplayer_peer = peer
			Debug.dprint('Server Created {ip}:{port}'.format({'ip': connection_mode.server_ip, 'port': connection_mode.server_port}), peer_role)
			connection_peer_changed.emit(multiplayer.multiplayer_peer)
			multiplayer.emit_signal('peer_connected', 1)
	elif connection_mode is SteamConnectionMode:
		pass
	
	
func guest_join_server():
	peer_role = 'guest'
	if connection_mode is ENetMultiplayerConnectionMode:
		if connection_mode.server_ip != null and connection_mode.server_port != null:
			multiplayer.peer_connected.connect(_peer_connected)
			multiplayer.connected_to_server.connect(_connected_to_server)
			multiplayer.connection_failed.connect(_connection_failed)
			multiplayer.server_disconnected.connect(_server_disconnected)
			peer.create_client(connection_mode.server_ip, connection_mode.server_port)
			multiplayer.multiplayer_peer = peer
			Debug.dprint('Client Created {ip}:{port}'.format({'ip': connection_mode.server_ip, 'port': connection_mode.server_port}), peer_role)
			connection_peer_changed.emit(multiplayer.multiplayer_peer)
	elif connection_mode is SteamConnectionMode:
		pass
		

func disconnect_peer_by_id():
	pass
	

func _peer_connected(peer_id):
	Debug.dprint('Peer Connected ' + str(peer_id), peer_role)


func _peer_disconnected(peer_id):
	Debug.dprint('Peer Disconnected ' + str(peer_id), peer_role)


func _connected_to_server():
	my_peer_id = multiplayer.get_unique_id()
	Debug.dprint('Connected to Server', peer_role)


func _connection_failed():
	Debug.dprint('Connection Failed', peer_role)


func _server_disconnected():
	Debug.dprint('Server Disconnected', peer_role)
