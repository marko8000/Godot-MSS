extends ConnectionMode
class_name ENetMultiplayerConnectionMode


@export var server_ip : String = '127.0.0.1' # move to connection_type
@export var server_port : int = 17172 # move to connection_type

var peer := ENetMultiplayerPeer.new()

func create_server() -> MultiplayerPeer:
	peer.create_server(server_port)
	Debug.dprint('Server Created {ip}:{port}'.format({'ip': server_ip, 'port': server_port}))
	return peer
	
	
func join_server() -> MultiplayerPeer:
	peer.create_client(server_ip, server_port)
	Debug.dprint('Client Created {ip}:{port}'.format({'ip': server_ip, 'port': server_port}))
	return peer
