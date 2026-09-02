@abstract
extends Resource
class_name MultiplayerAction


@export var action_name : String
@export var events : Array[PlayerInputEvent]


func write_buffer(input_buffer : StreamPeerBuffer, action_num : int):
	pass
	
	
func read_buffer(input_buffer : StreamPeerBuffer, action_num : int, input_signal : MultiplayerInput.MultiplayerInputSignal):
	pass
