@abstract
@icon('res://levels/MSSCore/godot_icons/MultiplayerSpawner.svg')
extends Resource
class_name ConnectionMode


var max_client_count : int
var client_count : int


func create_server() -> MultiplayerPeer:
	return


func join_server() -> MultiplayerPeer:
	return
